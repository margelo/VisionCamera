// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation
import Foundation

/// Represents a single Frame the Camera "sees".
///
/// Typically, a ``CameraOutput`` like ``FrameOutput`` produces instances of this type.
///
/// The Frame is either **planar** or **non-planar** (``Frame/isPlanar``).
/// - A **planar** Frame's, often YUV, pixel data can be accessed on the CPU via ``Frame/getPlanes()``, where each ``FramePlane`` represents one plane of the pixel data. In YUV, this is often one **Y** Plane in full resolution and one **UV** Plane in half resolution.
/// - A **non-planar** Frame's, often RGB, pixel data can be accessed on the CPU via ``Frame/withUnsafeBytes(_:)`` as one contiguous block of memory. In this case, ``Frame/getPlanes()`` returns an empty array.
///
/// The Frame retains its native buffer until ``Frame/dispose()`` or deallocation. Release Frames promptly, otherwise the producing pipeline might stall. Separately retained sample buffers, pixel buffers, and Frame Planes remain valid after disposal.
public final class Frame {
  /// The retained native sample buffer, or `nil` after ``Frame/dispose()``. Retaining this value keeps the sample buffer alive independently of the Frame.
  public private(set) var sampleBuffer: CMSampleBuffer?
  /// The timestamp, orientation, and mirroring metadata associated with this media sample.
  public let metadata: MediaSampleMetadata
  private var planesCached: [FramePlane]?

  /// Creates a Frame that retains the given native sample buffer and its presentation metadata.
  public init(buffer: CMSampleBuffer, metadata: MediaSampleMetadata) {
    self.sampleBuffer = buffer
    self.metadata = metadata
  }

  /// The retained native pixel buffer, or `nil` after disposal. A separately retained buffer remains valid independently of this instance.
  public var pixelBuffer: CVPixelBuffer? { sampleBuffer?.imageBuffer }
  /// The native pixel buffer's allocation size in bytes, or `0` after disposal.
  public var memorySize: Int { pixelBuffer?.memorySize ?? 0 }
  /// Gets the presentation timestamp this Frame was timed at, in seconds. The timestamp remains available after disposal.
  public var timestamp: Double { metadata.timestamp.seconds }
  /// Indicates whether this ``Frame``'s pixel data must be
  /// interpreted as mirrored along the vertical axis.
  ///
  /// This value is always relative to the target output's mirror mode.
  /// (see ``CameraOutputConfiguration/mirrorMode``)
  ///
  /// Frames are not automatically mirroring their pixels
  /// because physically mirroring buffers is expensive.
  /// The Camera streams frames in the hardware's native
  /// mirroring mode and adjusts presentation later using
  /// metadata (such as EXIF), transforms, or here; a flag.
  ///
  /// - If the output is mirrored but the underlying pixel buffer is NOT,
  ///   `isMirrored` will be `true`. You must treat the pixels as flipped
  ///   (for example, read them right-to-left).
  /// - If both the output and the pixel buffer are mirrored
  ///   (for example when ``FrameOutputOptions/enablePhysicalBufferRotation``
  ///   is enabled), `isMirrored` will be `false` because the buffer already
  ///   matches the output orientation.
  /// - If neither the output nor the pixel buffer are mirrored,
  ///   `isMirrored` will be `false`.
  ///
  /// If you process the Frame, **you** must interpret the
  /// pixel data in this ``Frame`` as mirrored if
  /// `isMirrored` is true.
  /// In rendering libraries you would typically scale the
  /// ``Frame`` by `-1` on the X axis if it is mirrored
  /// to cancel out the mirroring at render time.
  ///
  /// Most ML libraries (for example Google MLKit) accept a mirroring flag for
  /// input images - pass `isMirrored` directly in those cases.
  public var isMirrored: Bool { metadata.isMirrored }
  /// The rotation of this ``Frame`` relative to the
  /// ``CameraOutput``'s target output orientation. (see
  /// ``CameraOutput/outputOrientation``)
  ///
  /// Frames are not automatically rotated to ``CameraOrientation/up`` because physically
  /// rotating buffers is expensive. The Camera streams frames in the
  /// hardware's native orientation and adjusts presentation later using
  /// metadata (such as EXIF), transforms, or here; a flag.
  ///
  /// Examples:
  /// - ``CameraOrientation/up`` - The Frame is already correctly oriented.
  /// - ``CameraOrientation/right`` - The pixel data is rotated +90° relative to the desired orientation.
  /// - ``CameraOrientation/left`` - The pixel data is rotated -90° relative to the desired orientation.
  /// - ``CameraOrientation/down`` - The pixel data is rotated 180° upside down relative to the desired orientation.
  ///
  /// If you process the Frame, **you** must interpret the
  /// pixel data in this ``Frame`` to be rotated by
  /// this `orientation`.
  /// In rendering libraries you would typically counter-rotate
  /// the ``Frame`` by this `orientation` to get
  /// it "up-right".
  ///
  /// Most ML libraries (for example Google MLKit) accept an
  /// orientation flag for input images - pass `orientation`
  /// directly in those cases.
  public var orientation: CameraOrientation { metadata.orientation }
  /// Gets the total width of the Frame.
  ///
  /// If this is a planar Frame (see ``Frame/isPlanar``),
  /// the individual planes (see ``Frame/getPlanes()``)
  /// will likely have different widths than the total width.
  /// For example, a YUV Frame's UV Plane is half the size of its Y Plane.
  ///
  /// - Note: If this Frame is invalid (``Frame/isValid``), this just returns `0`.
  public var width: Double { pixelBuffer.map { Double(CVPixelBufferGetWidth($0)) } ?? 0 }
  /// Gets the total height of the Frame.
  ///
  /// If this is a planar Frame (see ``Frame/isPlanar``),
  /// the individual planes (see ``Frame/getPlanes()``)
  /// will likely have different heights than the total height.
  /// For example, a YUV Frame's UV Plane is half the size of its Y Plane.
  ///
  /// - Note: If this Frame is invalid (``Frame/isValid``), this just returns `0`.
  public var height: Double { pixelBuffer.map { Double(CVPixelBufferGetHeight($0)) } ?? 0 }
  /// Get the number of bytes per row of the underlying pixel buffer.
  ///
  /// For planar Frames, use the number of bytes per row of individual planes from ``Frame/getPlanes()`` and ``FramePlane/bytesPerRow``.
  public var bytesPerRow: Double { pixelBuffer.map { Double(CVPixelBufferGetBytesPerRow($0)) } ?? 0 }
  /// Gets whether this Frame still has a valid sample buffer. After ``Frame/dispose()``, pixel access throws.
  public var isValid: Bool { sampleBuffer?.isValid ?? false }
  /// Returns whether this Frame is **planar** or **non-planar**.
  /// - If a Frame is **planar**, for example YUV, access the individual planes through ``Frame/getPlanes()`` and ``FramePlane/withUnsafeBytes(_:)``.
  /// - If a Frame is **non-planar**, for example RGB, access its contiguous data through ``Frame/withUnsafeBytes(_:)``.
  ///
  /// - Note: If this Frame is invalid, this returns `false`.
  public var isPlanar: Bool { pixelBuffer.map { CVPixelBufferIsPlanar($0) } ?? false }
  /// Get whether this Frame has a `CVPixelBuffer` attached to it. Returns `false` after disposal.
  public var hasPixelBuffer: Bool { pixelBuffer != nil }

  /// Gets the ``PixelFormat`` of this Frame's pixel data.
  ///
  /// Frames are usually not in Depth Pixel Formats unless they have been manually converted from a ``Depth`` Frame to a ``Frame``.
  ///
  /// - Note: If this Frame is invalid (``Frame/isValid``), this returns ``PixelFormat/unknown``.
  public var pixelFormat: PixelFormat {
    guard let pixelBuffer else { return .unknown }
    return PixelFormat(osType: CVPixelBufferGetPixelFormatType(pixelBuffer))
  }

  /// Gets the Camera intrinsic matrix for this Frame.
  ///
  /// The returned value is a native 3x3 matrix with column-major indexing.
  /// Its origin is the top-left of the Frame.
  ///
  /// ```
  /// K = [ fx   0  cx ]
  ///     [  0  fy  cy ]
  ///     [  0   0   1 ]
  /// ```
  /// - `fx`, `fy`: focal length in pixels
  /// - `cx`, `cy`: principal point in pixels
  ///
  /// - Note: The ``Frame`` only has a Camera intrinsic matrix attached
  /// if ``FrameOutputOptions/enableCameraMatrixDelivery``
  /// is set to true on the `FrameOutput`.
  ///
  /// ```swift
  /// if let matrix = frame.cameraIntrinsicMatrix {
  ///   let fx = matrix[0, 0]
  ///   let fy = matrix[1, 1]
  /// }
  /// ```
  public var cameraIntrinsicMatrix: simd_float3x3? {
    sampleBuffer?.getCameraIntrinsicMatrix()
  }

  /// Releases this instance's reference to its native buffer early.
  ///
  /// Repeated calls have no effect. Buffers and Planes retained separately remain valid. ARC also releases the reference when this instance is deallocated.
  public func dispose() {
    sampleBuffer = nil
    planesCached = nil
  }

  /// Returns each plane of a **planar** Frame (see ``Frame/isPlanar``).
  /// If this Frame is **non-planar**, this method returns an empty array (`[]`).
  ///
  /// - Throws: If this Frame is invalid (``Frame/isValid``).
  public func getPlanes() throws -> [FramePlane] {
    let pixelBuffer = try getPixelBuffer()
    if let planesCached { return planesCached }
    let planes = try (0..<CVPixelBufferGetPlaneCount(pixelBuffer)).map { index in
      try FramePlane(buffer: pixelBuffer, planeIndex: index)
    }
    planesCached = planes
    return planes
  }

  /// Returns the retained native `CVPixelBuffer` without copying its pixels.
  ///
  /// The returned buffer remains valid after this instance is disposed while the caller retains it.
  /// - Throws: If this instance has been disposed or has no pixel buffer.
  public func getPixelBuffer() throws -> CVPixelBuffer {
    guard isValid else { throw CameraError(message: "This frame has been disposed or invalidated.") }
    guard let pixelBuffer else { throw CameraError(message: "This frame does not contain a pixel buffer.") }
    return pixelBuffer
  }

  /// Provides scoped, read-only access to the non-planar pixel buffer's bytes without copying them.
  ///
  /// The buffer is locked for the duration of `body` and unlocked even if `body` throws. The pointer must not escape the closure. Copy the bytes into `Data` to keep them beyond the closure.
  ///
  /// - Throws: If the buffer is unavailable, it is planar, locking fails, or `body` throws.
  ///
  /// ```swift
  /// let bytes = try frame.withUnsafeBytes { Data($0) }
  /// frame.dispose()
  /// print(bytes.count) // The copied data is still valid.
  /// ```
  public func withUnsafeBytes<Result>(_ body: (UnsafeRawBufferPointer) throws -> Result) throws -> Result {
    let pixelBuffer = try getPixelBuffer()
    return try pixelBuffer.withReadOnlyBytes(body)
  }

  /// Converts the given `cameraPoint` in
  /// camera sensor coordinates into a ``Point``
  /// in Frame coordinates, relative to this ``Frame``.
  ///
  /// Camera sensor coordinates are normalized from `0.0` to `1.0` in the unrotated, unmirrored image.
  ///
  /// ```swift
  /// let cameraPoint = Point(x: 0.5, y: 0.5)
  /// let framePoint = try frame.convertCameraPointToFramePoint(cameraPoint: cameraPoint)
  /// ```
  public func convertCameraPointToFramePoint(cameraPoint: Point) throws -> Point {
    let pixelBuffer = try getPixelBuffer()
    let matrix = FrameCoordinateSystemConverter.getCameraToFrameMatrix(
      pixelBuffer: pixelBuffer, orientation: orientation, isMirrored: isMirrored)
    return cameraPoint.applying(matrix)
  }

  /// Converts the given `framePoint` in
  /// Frame coordinates relative to this ``Frame``
  /// into a ``Point`` in camera sensor coordinates.
  ///
  /// Camera sensor coordinates are normalized from `0.0` to `1.0` in the unrotated, unmirrored image.
  ///
  /// ```swift
  /// let framePoint = Point(x: frame.width / 2, y: frame.height / 2)
  /// let cameraPoint = try frame.convertFramePointToCameraPoint(framePoint: framePoint)
  /// ```
  public func convertFramePointToCameraPoint(framePoint: Point) throws -> Point {
    let pixelBuffer = try getPixelBuffer()
    let matrix = FrameCoordinateSystemConverter.getFrameToCameraMatrix(
      pixelBuffer: pixelBuffer, orientation: orientation, isMirrored: isMirrored)
    return framePoint.applying(matrix)
  }
}
