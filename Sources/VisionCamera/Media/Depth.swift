// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation
import CoreGraphics
import Foundation

/// A depth or disparity sample captured by a ``DepthOutput``.
///
/// The value retains its native depth data. Copies and separately retained pixel buffers share the
/// same native storage without copying pixels. Release values promptly when processing is complete.
public struct Depth {
  /// The retained native depth data and calibration information.
  public let depthData: AVDepthData
  /// The timestamp, orientation, and mirroring metadata associated with this sample.
  public let metadata: MediaSampleMetadata
  private static let conversionQueue = DispatchQueue(label: "com.margelo.camera.depth-conversion", qos: .userInitiated)

  /// Creates a Depth value that retains native depth data and its presentation metadata.
  public init(depthData: AVDepthData, metadata: MediaSampleMetadata) {
    self.depthData = depthData
    self.metadata = metadata
  }

  /// The native pixel buffer containing depth or disparity values.
  public var pixelBuffer: CVPixelBuffer { depthData.depthDataMap }
  /// The depth map's storage size in bytes.
  public var byteCount: Int { CVPixelBufferGetDataSize(pixelBuffer) }
  /// The depth map's width in pixels.
  public var width: Int { CVPixelBufferGetWidth(pixelBuffer) }
  /// The depth map's height in pixels.
  public var height: Int { CVPixelBufferGetHeight(pixelBuffer) }
  /// The depth map's row stride, in bytes.
  public var bytesPerRow: Int { CVPixelBufferGetBytesPerRow(pixelBuffer) }
  /// The presentation timestamp associated with this depth sample.
  public var timestamp: CMTime { metadata.timestamp }
  /// The pixels' rotation relative to the output's target orientation.
  public var orientation: CameraOrientation { metadata.orientation }
  /// Whether the depth map must be interpreted as mirrored along its vertical axis.
  public var isMirrored: Bool { metadata.isMirrored }
  /// Whether the capture pipeline filtered the depth map to reduce noise and smooth uneven regions.
  public var isFiltered: Bool { depthData.isDepthDataFiltered }
  /// The storage format of the depth or disparity values.
  public var pixelFormat: DepthPixelFormat { DepthPixelFormat(osType: depthData.depthDataType) }
  /// Whether measurements represent absolute distances or relative depth.
  public var accuracy: DepthDataAccuracy { DepthDataAccuracy(av: depthData.depthDataAccuracy) }
  /// The capture pipeline's quality classification for this depth sample.
  public var quality: DepthDataQuality { DepthDataQuality(av: depthData.depthDataQuality) }
  /// The formats this sample can be converted to through ``Depth/converted(to:)``.
  public var availablePixelFormats: [DepthPixelFormat] {
    depthData.availableDepthDataTypes.map { DepthPixelFormat(osType: $0) }
  }
  /// Calibration data for projecting depth values into Camera or world coordinates, if available.
  public var calibrationData: CameraCalibrationData? {
    depthData.cameraCalibrationData.map { CameraCalibrationData(calibrationData: $0) }
  }

  /// Provides scoped, read-only access to the depth map's bytes without copying them.
  ///
  /// The buffer stays locked throughout `body` and is unlocked even if `body` throws. The pointer must
  /// not escape the closure. Copy it into `Data` to keep the bytes beyond the closure.
  /// - Throws: A ``MediaError`` if the buffer cannot be accessed, or the error thrown by `body`.
  public func withUnsafeBytes<Result>(_ body: (UnsafeRawBufferPointer) throws -> Result) throws -> Result {
    try pixelBuffer.withReadOnlyBytes(body)
  }

  /// Returns a depth map with an additional rotation and optional mirror transform applied to its pixels.
  ///
  /// AVFoundation transforms the depth data and its calibration information on a shared serial queue.
  /// The returned value keeps this sample's presentation metadata; the supplied transform describes an
  /// additional pixel transformation, not a replacement for that metadata.
  /// - Throws: `CancellationError` if the calling task is already cancelled.
  public func rotated(by orientation: CameraOrientation, mirrored: Bool = false) async throws -> Depth {
    try Task.checkCancellation()
    return await Self.conversionQueue.perform {
      let rotated = depthData.applyingExifOrientation(orientation.toCGOrientation(isMirrored: mirrored))
      return Depth(depthData: rotated, metadata: metadata)
    }
  }

  /// Converts the depth map to another supported storage format on a shared serial queue.
  ///
  /// The returned value preserves the sample's presentation metadata. Converting to the current format
  /// shares this value's depth data without allocating another map.
  /// - Throws: ``MediaError/unsupportedDepthPixelFormat(_:)`` if the requested format is unavailable,
  ///   or `CancellationError` if the calling task is already cancelled.
  public func converted(to pixelFormat: DepthPixelFormat) async throws -> Depth {
    try Task.checkCancellation()
    let nativeFormat = try pixelFormat.cvPixelFormat
    guard nativeFormat != depthData.depthDataType else { return self }
    guard depthData.availableDepthDataTypes.contains(nativeFormat) else {
      throw MediaError.unsupportedDepthPixelFormat(pixelFormat)
    }
    return await Self.conversionQueue.perform {
      Depth(depthData: depthData.converting(toDepthDataType: nativeFormat), metadata: metadata)
    }
  }

  /// Converts a normalized Camera sensor point into this depth map's pixel coordinates.
  public func point(fromCameraPoint point: CGPoint) -> CGPoint {
    let matrix = FrameCoordinateSystemConverter.getCameraToFrameMatrix(
      pixelBuffer: pixelBuffer, orientation: orientation, isMirrored: isMirrored)
    return point.applying(matrix)
  }

  /// Converts a point in this depth map's pixel coordinates into normalized Camera sensor coordinates.
  public func cameraPoint(from point: CGPoint) -> CGPoint {
    let matrix = FrameCoordinateSystemConverter.getFrameToCameraMatrix(
      pixelBuffer: pixelBuffer, orientation: orientation, isMirrored: isMirrored)
    return point.applying(matrix)
  }

  /// Creates a ``Frame`` sharing this depth map's pixel buffer and presentation metadata.
  ///
  /// This constructs a native sample-buffer wrapper without copying the pixels.
  /// - Throws: The underlying Core Media error if the format or sample buffer cannot be created.
  public func makeFrame() throws -> Frame {
    let format = try CMFormatDescription(imageBuffer: pixelBuffer)
    let timing = CMSampleTimingInfo(
      duration: .zero, presentationTimeStamp: timestamp, decodeTimeStamp: .invalid)
    let sampleBuffer = try CMSampleBuffer(
      imageBuffer: pixelBuffer, formatDescription: format, sampleTiming: timing)
    return Frame(sampleBuffer: sampleBuffer, metadata: metadata)
  }
}
