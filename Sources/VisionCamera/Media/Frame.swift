// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation
import CoreGraphics
import Foundation
import simd

/// Represents a single Frame the Camera sees.
///
/// A ``FrameOutput`` typically produces these values. Each Frame retains its native sample buffer;
/// copying the value shares the buffer without copying pixels. Release Frames promptly when finished
/// with them so the capture pipeline can reuse its buffers.
///
/// A sample buffer may contain no image, in which case ``Frame/pixelBuffer`` and its image dimensions
/// are `nil`. Native sample-buffer invalidation remains observable through ``Frame/isValid``.
public struct Frame {
  /// The retained native sample buffer. Its lifetime is independent of copies of this Frame.
  public let sampleBuffer: CMSampleBuffer
  /// The timestamp, orientation, and mirroring metadata associated with this sample.
  public let metadata: MediaSampleMetadata

  /// Creates a Frame that retains a native sample buffer and its presentation metadata.
  public init(sampleBuffer: CMSampleBuffer, metadata: MediaSampleMetadata) {
    self.sampleBuffer = sampleBuffer
    self.metadata = metadata
  }

  /// The native image buffer, or `nil` when the sample contains no image.
  ///
  /// A separately retained pixel buffer remains alive after this Frame goes out of scope.
  public var pixelBuffer: CVPixelBuffer? { sampleBuffer.imageBuffer }
  /// The image buffer's storage size in bytes, or `nil` when the sample contains no image.
  public var byteCount: Int? { pixelBuffer.map(CVPixelBufferGetDataSize) }
  /// The presentation timestamp associated with this Frame.
  public var timestamp: CMTime { metadata.timestamp }
  /// Whether the pixels must be interpreted as mirrored along the vertical axis.
  ///
  /// This flag is relative to the output's mirror setting. Pixels already physically mirrored to match
  /// that setting do not require another mirror operation.
  public var isMirrored: Bool { metadata.isMirrored }
  /// The pixels' rotation relative to the output's target orientation.
  ///
  /// Camera buffers normally stay in the sensor's native orientation. Consumers apply this metadata
  /// when displaying or processing them, unless physical buffer rotation is enabled on the output.
  public var orientation: CameraOrientation { metadata.orientation }
  /// The total image width in pixels, or `nil` when the sample contains no image.
  public var width: Int? { pixelBuffer.map(CVPixelBufferGetWidth) }
  /// The total image height in pixels, or `nil` when the sample contains no image.
  public var height: Int? { pixelBuffer.map(CVPixelBufferGetHeight) }
  /// The pixel buffer's row stride, or `nil` when the sample contains no image.
  ///
  /// For planar buffers, read the stride of each ``FramePlane`` instead.
  public var bytesPerRow: Int? { pixelBuffer.map(CVPixelBufferGetBytesPerRow) }
  /// Whether the native sample buffer remains valid according to Core Media.
  ///
  /// This reflects `CMSampleBufferIsValid`, including explicit native invalidation by a caller.
  public var isValid: Bool { CMSampleBufferIsValid(sampleBuffer) }
  /// Whether the image stores its pixels in separate planes, such as Y and UV.
  public var isPlanar: Bool { pixelBuffer.map(CVPixelBufferIsPlanar) ?? false }
  /// The image's pixel format, or `nil` when the sample contains no image.
  public var pixelFormat: PixelFormat? {
    pixelBuffer.map { PixelFormat(osType: CVPixelBufferGetPixelFormatType($0)) }
  }
  /// The Camera intrinsic matrix attached to this sample, if available.
  ///
  /// The matrix uses column-major layout. Its diagonal contains the horizontal and vertical focal
  /// lengths in pixels; the third column contains the principal point. Intrinsic matrix delivery must
  /// be enabled on the ``FrameOutput``. Missing or malformed native attachments produce `nil`.
  public var intrinsicMatrix: simd_float3x3? { sampleBuffer.cameraIntrinsicMatrix }

  /// The individual image planes. Non-planar images have no separate planes and return an empty array.
  ///
  /// Each ``FramePlane`` independently retains the pixel buffer. Reading this property does not copy pixels.
  /// - Throws: ``MediaError/invalidSampleBuffer`` or ``MediaError/missingPixelBuffer`` if image access is unavailable.
  public var planes: [FramePlane] {
    get throws(MediaError) {
      let buffer = try validatedPixelBuffer()
      var planes: [FramePlane] = []
      for index in 0..<CVPixelBufferGetPlaneCount(buffer) {
        planes.append(try FramePlane(pixelBuffer: buffer, index: index))
      }
      return planes
    }
  }

  /// Provides scoped, read-only access to a non-planar image's bytes without copying them.
  ///
  /// The pixel buffer stays locked throughout `body` and is unlocked even when `body` throws. The pointer
  /// must not escape the closure. Copy it into `Data` to keep bytes beyond the closure.
  /// - Throws: A ``MediaError`` if the sample is invalid, has no image, is planar, or cannot be locked;
  ///   otherwise propagates the error thrown by `body`.
  public func withUnsafeBytes<Result>(_ body: (UnsafeRawBufferPointer) throws -> Result) throws -> Result {
    try validatedPixelBuffer().withReadOnlyBytes(body)
  }

  /// Converts a normalized Camera sensor point into this Frame's pixel coordinates.
  ///
  /// Applies the Frame's orientation and mirroring metadata.
  /// - Throws: If the native sample is invalid or contains no image.
  public func point(fromCameraPoint point: CGPoint) throws(MediaError) -> CGPoint {
    let matrix = FrameCoordinateSystemConverter.getCameraToFrameMatrix(
      pixelBuffer: try validatedPixelBuffer(), orientation: orientation, isMirrored: isMirrored)
    return point.applying(matrix)
  }

  /// Converts a point in this Frame's pixel coordinates into normalized Camera sensor coordinates.
  ///
  /// Applies the Frame's orientation and mirroring metadata.
  /// - Throws: If the native sample is invalid or contains no image.
  public func cameraPoint(from point: CGPoint) throws(MediaError) -> CGPoint {
    let matrix = FrameCoordinateSystemConverter.getFrameToCameraMatrix(
      pixelBuffer: try validatedPixelBuffer(), orientation: orientation, isMirrored: isMirrored)
    return point.applying(matrix)
  }

  func validatedPixelBuffer() throws(MediaError) -> CVPixelBuffer {
    guard isValid else { throw .invalidSampleBuffer }
    guard let pixelBuffer else { throw .missingPixelBuffer }
    return pixelBuffer
  }
}
