// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation
import Foundation

/// A ``Depth`` Frame is a frame captured from a ``DepthOutput``.
///
/// It contains depth data that can be accessed through ``Depth/getDepthData()`` as `AVDepthData`, or through ``Depth/getPixelBuffer()`` as a `CVPixelBuffer`. The depth's format (``Depth/pixelFormat``) specifies the depth map's pixel format.
///
/// Release Depth Frames promptly, or call ``Depth/dispose()`` to release this instance's reference early, otherwise the producing pipeline might stall. Separately retained native data and pixel buffers remain valid after disposal.
public final class Depth {
  /// The retained native depth data, or `nil` after disposal. A separately retained value remains valid independently of this Depth instance.
  public private(set) var depthData: AVDepthData?
  /// The timestamp, orientation, and mirroring metadata associated with this media sample.
  public let metadata: MediaSampleMetadata
  private static let conversionQueue = DispatchQueue(label: "com.margelo.camera.depth-conversion", qos: .userInitiated)

  /// Creates a Depth Frame that retains the given `AVDepthData` and presentation metadata.
  public init(depthData: AVDepthData, metadata: MediaSampleMetadata) {
    self.depthData = depthData
    self.metadata = metadata
  }

  /// The retained native pixel buffer, or `nil` after disposal. A separately retained buffer remains valid independently of this instance.
  public var pixelBuffer: CVPixelBuffer? { depthData?.depthDataMap }
  /// The native pixel buffer's allocation size in bytes, or `0` after disposal.
  public var memorySize: Int { pixelBuffer?.memorySize ?? 0 }
  /// Gets whether this Depth Frame still retains native depth data. After ``Depth/dispose()``, data access throws.
  public var isValid: Bool { depthData != nil }
  /// Gets the total width of this ``Depth``.
  ///
  /// - Note: If this ``Depth`` is invalid (``Depth/isValid``), this may return `0`.
  public var width: Double { pixelBuffer.map { Double(CVPixelBufferGetWidth($0)) } ?? 0 }
  /// Gets the total height of this ``Depth``.
  ///
  /// - Note: If this ``Depth`` is invalid (``Depth/isValid``), this may return `0`.
  public var height: Double { pixelBuffer.map { Double(CVPixelBufferGetHeight($0)) } ?? 0 }
  /// Get the number of bytes per row of the
  /// underlying pixel buffer.
  ///
  /// This may return `0` if the ``Depth``
  /// is planar.
  ///
  /// See ``Depth/width``
  /// See ``Depth/getDepthData()``
  public var bytesPerRow: Double { pixelBuffer.map { Double(CVPixelBufferGetBytesPerRow($0)) } ?? 0 }
  /// Gets the presentation timestamp this Depth Frame was timed at, in seconds. The timestamp remains available after disposal.
  public var timestamp: Double { metadata.timestamp.seconds }
  /// The rotation of this ``Depth`` relative to the
  /// associated ``DepthOutput``'s target output orientation.
  ///
  /// Depth data is not automatically rotated to ``CameraOrientation/up`` because physically
  /// rotating buffers is expensive. The Camera streams depth frames in the
  /// hardware's native orientation and adjusts presentation later using
  /// metadata, transforms, or here; a flag.
  ///
  /// If you process this ``Depth``, **you** must interpret
  /// its pixel data to be rotated by this `orientation`.
  public var orientation: CameraOrientation { metadata.orientation }
  /// Gets whether this ``Depth`` frame is mirrored alongside the
  /// vertical axis.
  public var isMirrored: Bool { metadata.isMirrored }
  /// Gets whether the depth map has been filtered/smoothed by the platform.
  ///
  /// Filtering typically reduces noise and smoothens out uneven spots in
  /// the depth map at the cost of some fine detail.
  ///
  /// - Note: If this metadata is unavailable for this ``Depth``, this may be `false`.
  public var isDepthDataFiltered: Bool { depthData?.isDepthDataFiltered ?? false }

  /// Gets the ``DepthPixelFormat`` of this ``Depth`` Frame's
  /// pixel data.
  /// Common formats are ``DepthPixelFormat/depth16Bit``
  /// for depth frames, or ``DepthPixelFormat/disparity16Bit``
  /// for disparity frames.
  ///
  /// - Note: If this ``Depth`` frame is invalid (``Depth/isValid``),
  /// this just returns ``DepthPixelFormat/unknown``.
  public var pixelFormat: DepthPixelFormat {
    guard let depthData else { return .unknown }
    return DepthPixelFormat(osType: depthData.depthDataType)
  }

  /// Gets the measurement accuracy of this Depth Frame.
  /// - ``DepthDataAccuracy/absolute``: Depth values represent absolute distances.
  /// - ``DepthDataAccuracy/relative``: Depth values represent relative distances.
  /// - ``DepthDataAccuracy/unknown``: Accuracy is unknown or the Depth Frame is disposed.
  public var depthDataAccuracy: DepthDataAccuracy {
    guard let depthData else { return .unknown }
    return DepthDataAccuracy(av: depthData.depthDataAccuracy)
  }

  /// Gets the quality classification of this Depth Frame.
  /// - ``DepthDataQuality/high``: High quality depth data.
  /// - ``DepthDataQuality/low``: Lower quality depth data.
  /// - ``DepthDataQuality/unknown``: Quality is unknown or the Depth Frame is disposed.
  public var depthDataQuality: DepthDataQuality {
    guard let depthData else { return .unknown }
    return DepthDataQuality(av: depthData.depthDataQuality)
  }

  /// Gets the list of ``DepthPixelFormat``s this
  /// ``Depth`` can be converted to using ``Depth/convert(pixelFormat:)``.
  ///
  /// - Note: If this ``Depth`` is invalid (``Depth/isValid``), this returns an empty array (`[]`).
  /// - Note: Some platforms may return an empty array (`[]`) if conversion is not supported.
  public var availableDepthPixelFormats: [DepthPixelFormat] {
    depthData?.availableDepthDataTypes.map { DepthPixelFormat(osType: $0) } ?? []
  }

  /// Gets the associated ``CameraCalibrationData`` for this
  /// ``Depth``, if available.
  ///
  /// Camera calibration data can be used to project depth values into
  /// camera/world coordinates with higher accuracy.
  public var cameraCalibrationData: CameraCalibrationData? {
    depthData?.cameraCalibrationData.map { CameraCalibrationData(calibrationData: $0) }
  }

  /// Releases this instance's reference to its native buffer early.
  ///
  /// Repeated calls have no effect. Buffers and Planes retained separately remain valid. ARC also releases the reference when this instance is deallocated.
  public func dispose() { depthData = nil }

  /// Returns the retained `AVDepthData` without copying its map.
  ///
  /// The returned data remains valid after this instance is disposed while the caller retains it.
  /// - Throws: If this Depth Frame has been disposed.
  public func getDepthData() throws -> AVDepthData {
    guard let depthData else { throw CameraError(message: "This depth frame has been disposed.") }
    return depthData
  }

  /// Returns the retained native `CVPixelBuffer` without copying its pixels.
  ///
  /// The returned buffer remains valid after this instance is disposed while the caller retains it.
  /// - Throws: If this instance has been disposed or has no pixel buffer.
  public func getPixelBuffer() throws -> CVPixelBuffer { try getDepthData().depthDataMap }
  /// Returns the retained native `CVPixelBuffer` for use with native image, GPU, or encoder APIs.
  ///
  /// The returned buffer remains valid after this instance is disposed while the caller retains it.
  /// - Throws: If this instance has been disposed or has no pixel buffer.
  public func getNativeBuffer() throws -> CVPixelBuffer { try getPixelBuffer() }

  /// Provides scoped, read-only access to the non-planar pixel buffer's bytes without copying them.
  ///
  /// The buffer is locked for the duration of `body` and unlocked even if `body` throws. The pointer must not escape the closure. Copy the bytes into `Data` to keep them beyond the closure.
  ///
  /// - Throws: If the buffer is unavailable, it is planar, locking fails, or `body` throws.
  public func withUnsafeBytes<Result>(_ body: (UnsafeRawBufferPointer) throws -> Result) throws -> Result {
    let pixelBuffer = try getPixelBuffer()
    return try pixelBuffer.withReadOnlyBytes(body)
  }

  /// Returns a derivative ``Depth`` frame by rotating
  /// it to the specified ``Depth/orientation``, and potentially
  /// mirroring it.
  ///
  /// Applies the specified EXIF transform to the depth map. The returned Depth retains the original presentation metadata. Throws if this Depth Frame has been disposed.
  public func rotate(orientation: CameraOrientation, isMirrored: Bool) throws -> Depth {
    let depthData = try getDepthData()
    let rotated = depthData.applyingExifOrientation(orientation.toCGOrientation(isMirrored: isMirrored))
    return Depth(depthData: rotated, metadata: metadata)
  }

  /// Asynchronously returns a derivative ``Depth`` frame by rotating
  /// it to the specified ``Depth/orientation``, and potentially
  /// mirroring it.
  ///
  /// Applies the specified EXIF transform to the depth map. The returned Depth retains the original presentation metadata. Throws if this Depth Frame has been disposed. Rotation runs on the shared serial depth conversion queue.
  public func rotateAsync(orientation: CameraOrientation, isMirrored: Bool) async throws -> Depth {
    let depthData = try getDepthData()
    let metadata = metadata
    try Task.checkCancellation()
    return await Self.conversionQueue.perform {
      let rotated = depthData.applyingExifOrientation(orientation.toCGOrientation(isMirrored: isMirrored))
      return Depth(depthData: rotated, metadata: metadata)
    }
  }

  /// Converts this ``Depth`` frame to the target ``Depth/pixelFormat``.
  ///
  /// The ``Depth/pixelFormat`` must be one of the ``DepthPixelFormat``s
  /// returned from ``Depth/availableDepthPixelFormats``.
  ///
  /// The returned Depth retains the original presentation metadata. Throws if this Depth Frame has been disposed or the target pixel format is unsupported.
  public func convert(pixelFormat: DepthPixelFormat) throws -> Depth {
    let depthData = try getDepthData()
    let converted = depthData.converting(toDepthDataType: try pixelFormat.toCVPixelFormatType())
    return Depth(depthData: converted, metadata: metadata)
  }

  /// Asynchronously converts this ``Depth`` frame to the target ``Depth/pixelFormat``.
  ///
  /// The ``Depth/pixelFormat`` must be one of the ``DepthPixelFormat``s
  /// returned from ``Depth/availableDepthPixelFormats``.
  ///
  /// The returned Depth retains the original presentation metadata. Throws if this Depth Frame has been disposed or the target pixel format is unsupported. Conversion runs on the shared serial depth conversion queue.
  public func convertAsync(pixelFormat: DepthPixelFormat) async throws -> Depth {
    let depthData = try getDepthData()
    let metadata = metadata
    let osFormat = try pixelFormat.toCVPixelFormatType()
    try Task.checkCancellation()
    return await Self.conversionQueue.perform {
      Depth(depthData: depthData.converting(toDepthDataType: osFormat), metadata: metadata)
    }
  }

  /// Converts the given `cameraPoint` in
  /// camera sensor coordinates into a ``Point``
  /// in Depth coordinates, relative to this ``Depth``.
  ///
  /// - Note: Camera sensor coordinates are not necessarily normalized from `0.0` to `1.0`. Some implementations may have a different opaque coordinate system.
  ///
  /// ```swift
  /// let cameraPoint = Point(x: 0.5, y: 0.5)
  /// let depthPoint = try depth.convertCameraPointToDepthPoint(cameraPoint: cameraPoint)
  /// ```
  public func convertCameraPointToDepthPoint(cameraPoint: Point) throws -> Point {
    let matrix = FrameCoordinateSystemConverter.getCameraToFrameMatrix(
      pixelBuffer: try getPixelBuffer(), orientation: orientation, isMirrored: isMirrored)
    return cameraPoint.applying(matrix)
  }

  /// Converts the given `depthPoint` in
  /// Depth coordinates relative to this ``Depth``
  /// into a ``Point`` in camera sensor coordinates.
  ///
  /// - Note: Camera sensor coordinates are not necessarily normalized from `0.0` to `1.0`. Some implementations may have a different opaque coordinate system.
  ///
  /// ```swift
  /// let depthPoint = Point(x: depth.width / 2, y: depth.height / 2)
  /// let cameraPoint = try depth.convertDepthPointToCameraPoint(depthPoint: depthPoint)
  /// ```
  public func convertDepthPointToCameraPoint(depthPoint: Point) throws -> Point {
    let matrix = FrameCoordinateSystemConverter.getFrameToCameraMatrix(
      pixelBuffer: try getPixelBuffer(), orientation: orientation, isMirrored: isMirrored)
    return depthPoint.applying(matrix)
  }

  /// Converts this Depth Frame to a ``Frame``.
  ///
  /// The resulting Frame contains the depth/disparity data in the current format, retains the shared pixel buffer independently, and preserves the presentation metadata. Release it promptly or call ``Frame/dispose()`` when no longer needed.
  /// - Throws: If this Depth Frame has been disposed or a native sample buffer cannot be created.
  public func toFrame() throws -> Frame {
    let pixelBuffer = try getPixelBuffer()
    let format = try CMFormatDescription(imageBuffer: pixelBuffer)
    let timing = CMSampleTimingInfo(
      duration: .zero, presentationTimeStamp: metadata.timestamp, decodeTimeStamp: .zero)
    let sampleBuffer = try CMSampleBuffer(
      imageBuffer: pixelBuffer, formatDescription: format, sampleTiming: timing)
    return Frame(buffer: sampleBuffer, metadata: metadata)
  }
}
