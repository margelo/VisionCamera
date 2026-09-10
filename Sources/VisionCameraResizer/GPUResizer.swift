// Copyright © 2025 Marc Rousavy @ Margelo
// Adapted from Marc Rousavy's iOS resizer, created 29.10.25.

import CoreVideo
import VisionCamera

/// Resizes full-range NV12 images into shared Metal buffers containing RGB or BGR tensors.
///
/// Use one instance on one serial queue, such as a `FrameOutput` callback queue. The first resize lazily creates
/// the Metal pipeline. Each call waits for GPU completion before returning, so this instance never queues a backlog.
/// Retained results occupy a bounded pool. Release a result before the pool reaches ``maximumOutstandingResults``.
/// Do not call this blocking operation on the main thread during live capture.
public final class GPUResizer {
  /// The fixed dimensions and encoding of every output result.
  public let options: ResizerOptions
  /// The maximum number of independently retained results. Further calls fail with ``GPUResizerError/outputCapacityExceeded``.
  public let maximumOutstandingResults: Int
  private var pipeline: MetalResizerPipeline?

  /// Creates a resizer and validates its configuration without allocating GPU resources.
  ///
  /// - Parameters:
  ///   - options: The fixed output dimensions and tensor encoding.
  ///   - maximumOutstandingResults: The capacity of the reusable output pool. Buffers allocate lazily, up to this limit.
  /// - Throws: ``GPUResizerError/invalidDimensions`` or ``GPUResizerError/invalidCapacity`` for invalid configuration.
  public init(options: ResizerOptions, maximumOutstandingResults: Int = 3) throws {
    _ = try options.validatedByteCount()
    guard maximumOutstandingResults > 0 else { throw GPUResizerError.invalidCapacity }
    self.options = options
    self.maximumOutstandingResults = maximumOutstandingResults
  }

  /// Resizes a Frame using its orientation and mirroring metadata.
  ///
  /// The source buffer stays retained through GPU completion. The returned result owns its output independently of the Frame.
  /// Dispose the Frame after this method returns. Call this method only on the instance's serial owner queue.
  /// - Throws: If the Frame is disposed, the input format is unsupported, the output pool is full, or Metal fails.
  public func resize(_ frame: Frame) throws -> GPUResizeResult {
    return try resize(try frame.getPixelBuffer(), orientation: frame.orientation, isMirrored: frame.isMirrored)
  }

  /// Resizes a native full-range NV12 pixel buffer and waits for GPU completion.
  ///
  /// The resizer uses bilinear sampling and the source implementation's full-range BT.601 YCbCr conversion.
  /// Color attachments do not select another matrix. `.right` rotates the pixels 90 degrees clockwise.
  /// Mirroring flips the source's horizontal axis before rotation. Output rows have no padding.
  /// Call this method only on the instance's serial owner queue and do not modify the input while this method runs.
  /// - Parameters:
  ///   - pixelBuffer: A Metal-compatible `kCVPixelFormatType_420YpCbCr8BiPlanarFullRange` buffer.
  ///   - orientation: The clockwise presentation rotation to apply to the source pixels.
  ///   - isMirrored: Whether to mirror the source's horizontal axis before rotation.
  /// - Throws: If the input format is unsupported, the output pool is full, shader resources are missing, or Metal fails.
  public func resize(_ pixelBuffer: CVPixelBuffer, orientation: CameraOrientation = .up, isMirrored: Bool = false) throws -> GPUResizeResult {
    let format = CVPixelBufferGetPixelFormatType(pixelBuffer)
    guard format == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange else {
      throw GPUResizerError.unsupportedPixelFormat(format)
    }
    if pipeline == nil {
      pipeline = try MetalResizerPipeline(options: options, capacity: maximumOutstandingResults)
    }
    guard let pipeline else { throw GPUResizerError.metalUnavailable }
    return try withExtendedLifetime(pixelBuffer) {
      try pipeline.run(pixelBuffer: pixelBuffer, rotationDegrees: orientation.resizerRotationDegrees, isMirrored: isMirrored)
    }
  }
}
