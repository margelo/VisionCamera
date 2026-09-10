// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation
import Foundation
import UIKit

/// A captured Photo in memory.
///
/// ``PhotoOutput`` produces Photos. Each value retains its native capture result, so copies share the
/// image data without copying pixels. Use ``Photo/image()`` to display the Photo or ``Photo/write(to:options:)``
/// to encode it to a file. Release retained Photos when they are no longer needed.
public struct Photo {
  /// The retained native capture result, including image data and capture metadata.
  public let photo: AVCapturePhoto
  /// The orientation, mirroring, and timing metadata associated with this capture.
  public let metadata: MediaSampleMetadata
  /// The container format used when encoding this Photo.
  public let containerFormat: PhotoContainerFormat
  private static let processingQueue = DispatchQueue(label: "com.margelo.camera.photo-processing", qos: .userInitiated)
  private static let fileQueue = DispatchQueue(label: "com.margelo.camera.photo-files", qos: .utility)

  /// Creates a Photo that retains a native capture result and its metadata.
  public init(photo: AVCapturePhoto, metadata: MediaSampleMetadata, containerFormat: PhotoContainerFormat) {
    self.photo = photo
    self.metadata = metadata
    self.containerFormat = containerFormat
  }

  /// The native capture timestamp on the system's host clock.
  public var timestamp: CMTime { photo.timestamp }
  /// Whether the Photo's pixels must be interpreted as mirrored along the vertical axis.
  public var isMirrored: Bool { metadata.isMirrored }
  /// The capture orientation, applied as metadata when encoding or displaying the Photo.
  public var orientation: CameraOrientation { metadata.orientation }
  /// Whether this capture contains RAW sensor data rather than a processed image.
  public var isRaw: Bool { photo.isRawPhoto }
  /// The native pixel buffer, if AVFoundation included one with this capture.
  ///
  /// A separately retained buffer remains alive after the Photo goes out of scope.
  public var pixelBuffer: CVPixelBuffer? { photo.pixelBuffer }
  /// The Photo's width in pixels.
  public var width: Int { Int(dimensions.width) }
  /// The Photo's height in pixels.
  public var height: Int { Int(dimensions.height) }
  /// The native image dimensions for the RAW or processed capture result.
  public var dimensions: CMVideoDimensions {
    isRaw ? photo.resolvedSettings.rawPhotoDimensions : photo.resolvedSettings.photoDimensions
  }
  /// The captured depth data, if depth delivery was enabled and supported for this Photo.
  public var depth: Depth? {
    photo.depthData.map { Depth(depthData: $0, metadata: metadata) }
  }
  /// Camera calibration data attached to this Photo, if available.
  public var calibrationData: CameraCalibrationData? {
    photo.cameraCalibrationData.map { CameraCalibrationData(calibrationData: $0) }
  }

  /// Provides scoped, read-only access to the Photo's non-planar pixel buffer.
  ///
  /// The buffer stays locked throughout `body` and is unlocked even if `body` throws. The pointer must
  /// not escape the closure. Copy it into `Data` to keep the bytes beyond the closure.
  /// - Throws: A ``MediaError`` if the Photo has no accessible non-planar buffer, or the error thrown by `body`.
  public func withUnsafeBytes<Result>(_ body: (UnsafeRawBufferPointer) throws -> Result) throws -> Result {
    guard let pixelBuffer else { throw MediaError.missingPixelBuffer }
    return try pixelBuffer.withReadOnlyBytes(body)
  }

  /// Encodes this Photo, including EXIF metadata, on a shared serial processing queue.
  ///
  /// The returned `Data` owns its bytes independently of the Photo.
  /// - Throws: ``MediaError/photoDataUnavailable`` if AVFoundation cannot encode the Photo,
  ///   or `CancellationError` if cancelled before encoding begins.
  public func encodedData() async throws -> Data {
    try await Self.processingQueue.perform { try encodedRepresentation() }
  }

  /// Encodes this Photo and writes it to a file on a shared serial file queue.
  ///
  /// Parent directories must exist. By default, writing replaces an existing file atomically. Pass
  /// `Data.WritingOptions.withoutOverwriting` to require a new destination.
  /// - Parameters:
  ///   - url: A file URL including the destination filename and extension.
  ///   - options: Foundation's file-writing options. Defaults to an atomic write.
  /// - Throws: ``MediaError/invalidFileURL(_:)`` for a non-file URL, an encoding error, the underlying
  ///   file-system error, or `CancellationError` if cancelled before writing begins.
  public func write(to url: URL, options: Data.WritingOptions = .atomic) async throws {
    guard url.isFileURL else { throw MediaError.invalidFileURL(url) }
    try await Self.fileQueue.perform {
      try encodedRepresentation().write(to: url, options: options)
    }
  }

  /// Encodes this Photo to a new temporary file and returns its file URL.
  ///
  /// The extension follows ``Photo/containerFormat``. Encoding and writing run on a shared serial queue.
  /// The caller is responsible for removing the temporary file when it is no longer needed.
  /// - Throws: A format or encoding error, the underlying file-system error, or cancellation before writing begins.
  public func writeToTemporaryFile() async throws -> URL {
    try await Self.fileQueue.perform {
      let fileType = try containerFormat.uniformType
      let url = try URL.createTempURL(fileType: fileType)
      try encodedRepresentation().write(to: url, options: .atomic)
      return url
    }
  }

  /// Creates a UIKit image carrying this Photo's orientation and mirroring metadata.
  ///
  /// Conversion runs on a shared serial processing queue. RAW Photos may not have a processed image
  /// representation; use ``Photo/encodedData()`` to retain their RAW capture data.
  /// - Throws: ``MediaError/photoImageUnavailable(isRaw:)`` if no image representation is available,
  ///   or cancellation before conversion begins.
  public func image() async throws -> UIImage {
    try await Self.processingQueue.perform {
      guard let cgImage = photo.cgImageRepresentation() else {
        throw MediaError.photoImageUnavailable(isRaw: isRaw)
      }
      return UIImage(cgImage: cgImage, scale: 1, orientation: metadata.uiImageOrientation)
    }
  }

  private func encodedRepresentation() throws(MediaError) -> Data {
    guard let data = photo.fileDataRepresentation() else { throw .photoDataUnavailable }
    return data
  }
}
