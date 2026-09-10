import AVFoundation
import Foundation

/// A renderer that displays native Camera Frames without copying their pixels.
///
/// Connect it to a ``FrameRendererView`` to display Frames on screen. Calls using the same renderer
/// must be serialized. Layer attachment and layout belong on the main actor.
public final class FrameRenderer {
  /// The sample-buffer display layer that receives Frames.
  public let layer = AVSampleBufferDisplayLayer()

  /// Creates a renderer backed by a native sample-buffer display layer.
  public init() {}

  /// Enqueues a Frame for display without copying its pixels.
  ///
  /// Returns after enqueueing; the display layer presents the sample according to its timing.
  /// - Throws: A ``MediaError`` if the sample is invalid or contains no image, or the display layer's
  ///   underlying error when rendering fails.
  public func render(_ frame: Frame) throws {
    _ = try frame.validatedPixelBuffer()
    if layer.requiresFlushToResumeDecoding { layer.flush() }
    layer.enqueue(frame.sampleBuffer)
    if layer.status == .failed {
      throw layer.error ?? MediaError.frameRenderingFailed
    }
  }
}
