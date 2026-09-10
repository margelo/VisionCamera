// Copyright © 2026 Marc Rousavy @ Margelo

import CoreImage
import CoreVideo
import Foundation
import ImageIO
import Vision

/// Detects barcodes with Apple's on-device Vision machine learning detector.
///
/// Scans execute synchronously on the calling queue. Use a background queue or a `FrameOutput`
/// callback. Each scanner accepts one scan at a time and rejects concurrent scans with
/// ``BarcodeScannerError/busy`` instead of accumulating images. Results own their values and
/// remain valid after the input Frame is disposed.
///
/// iOS 16 uses Vision request revision 3. iOS 17 and later use revision 4.
/// Both revisions use machine learning. See <doc:BarcodeBackend> for the differences from ML Kit.
@available(iOS 16.0, *)
public final class BarcodeScanner {
  /// The validated options used by this scanner.
  public let options: BarcodeScannerOptions
  private let revision: Int
  private let symbologies: [VNBarcodeSymbology]
  private let computeConfiguration: BarcodeComputeConfiguration
  private let handler = VNSequenceRequestHandler()
  private let state = BarcodeScanState()

  /// Creates a scanner and validates its requested symbologies against the running OS.
  ///
  /// Creating a scanner does not start a Camera or request permission. Reuse it across scans.
  /// - Throws: ``BarcodeScannerError/emptySymbologies``, ``BarcodeScannerError/unsupportedSymbologies(_:)``, or a Vision configuration error.
  public init(options: BarcodeScannerOptions = .init()) throws {
    self.options = options
    let request = VNDetectBarcodesRequest()
    if #available(iOS 17.0, *) {
      self.revision = VNDetectBarcodesRequestRevision4
    } else {
      self.revision = VNDetectBarcodesRequestRevision3
    }
    request.revision = revision
    self.computeConfiguration = try BarcodeComputeConfiguration(request: request)
    let supported = try request.supportedSymbologies()
    if let requested = options.symbologies {
      guard !requested.isEmpty else { throw BarcodeScannerError.emptySymbologies }
      let unsupported = requested.filter { !supported.contains($0) }
      guard unsupported.isEmpty else { throw BarcodeScannerError.unsupportedSymbologies(unsupported) }
      self.symbologies = Array(Set(requested)).sorted { $0.rawValue < $1.rawValue }
    } else {
      self.symbologies = supported
    }
  }

  /// Returns the symbologies supported by the detector revision selected for the running OS.
  ///
  /// This queries Vision and can be expensive. Cache the result instead of calling it per Frame.
  public static func supportedSymbologies() throws -> [VNBarcodeSymbology] {
    let request = VNDetectBarcodesRequest()
    if #available(iOS 17.0, *) {
      request.revision = VNDetectBarcodesRequestRevision4
    } else {
      request.revision = VNDetectBarcodesRequestRevision3
    }
    return try request.supportedSymbologies()
  }

  /// Scans a pixel buffer using the EXIF orientation required to display it upright.
  ///
  /// The buffer is retained during the call without copying its pixels. Do not modify it until
  /// the call returns. Result coordinates are pixels in the oriented image, with a top-left origin.
  public func scan(pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation = .up) throws -> [Barcode] {
    let size = CGSize(width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))
    return try perform(size: size, orientation: orientation) { request in
      try handler.perform([request], on: pixelBuffer, orientation: orientation)
    }
  }

  /// Scans a Core Graphics image using the EXIF orientation required to display it upright.
  ///
  /// Result coordinates are pixels in the oriented image, with a top-left origin.
  public func scan(image: CGImage, orientation: CGImagePropertyOrientation = .up) throws -> [Barcode] {
    let size = CGSize(width: image.width, height: image.height)
    return try perform(size: size, orientation: orientation) { request in
      try handler.perform([request], on: image, orientation: orientation)
    }
  }

  /// Scans a Core Image image using the supplied EXIF orientation.
  ///
  /// Result coordinates are pixels relative to the oriented image extent, with a top-left origin.
  /// - Throws: ``BarcodeScannerError/unsupportedImage`` if the image's extent is empty or not finite.
  public func scan(image: CIImage, orientation: CGImagePropertyOrientation = .up) throws -> [Barcode] {
    guard !image.extent.isInfinite, !image.extent.isNull, !image.extent.isEmpty,
      image.extent.width.isFinite, image.extent.height.isFinite
    else {
      throw BarcodeScannerError.unsupportedImage
    }
    return try perform(size: image.extent.size, orientation: orientation) { request in
      try handler.perform([request], on: image, orientation: orientation)
    }
  }

  /// Cancels the currently accepted scan, if any, from any queue.
  ///
  /// Cancellation is cooperative. The scan retains its input until Vision returns, then throws
  /// ``BarcodeScannerError/cancelled``. A completed scan and future scans are unaffected.
  /// To stop a Camera stream, also remove its `FrameOutput` callback.
  public func cancel() {
    state.cancel()
  }

  private func perform(
    size: CGSize,
    orientation: CGImagePropertyOrientation,
    scan: (VNDetectBarcodesRequest) throws -> Void
  ) throws -> [Barcode] {
    // Each operation has a distinct cancellation identity. The sequence handler reuses Vision resources.
    let request = VNDetectBarcodesRequest()
    request.revision = revision
    request.symbologies = symbologies
    computeConfiguration.apply(to: request)
    try state.begin(request)
    let result: Result<[Barcode], Error> = Result {
      try autoreleasepool {
        try scan(request)
        let imageSize = BarcodeImageGeometry.orientedSize(size, orientation: orientation)
        return (request.results ?? []).map { Barcode(observation: $0, imageSize: imageSize) }
      }
    }
    guard !state.finish() else { throw BarcodeScannerError.cancelled }
    return try result.get()
  }
}
