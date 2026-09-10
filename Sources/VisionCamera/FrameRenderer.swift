import AVFoundation
import Foundation

/// A ``FrameRenderer`` is an object that can render ``Frame``s into a given target.
///
/// For example, when a ``FrameRendererView`` is connected to a FrameRenderer, it renders its Frames on screen.
public final class FrameRenderer {
  /// The sample-buffer display layer that receives rendered Frames. Attach or lay out this layer on the main actor.
  public let layer = AVSampleBufferDisplayLayer()

  /// Creates a Frame renderer backed by an `AVSampleBufferDisplayLayer`.
  public init() {}

  /// Synchronously renders the given ``Frame``.
  ///
  /// The sample buffer is enqueued without copying its pixels. Throws if the Frame is disposed or the display layer reports a rendering error. Calls that render through the same renderer must be serialized.
  public func renderFrame(frame: Frame) throws {
    guard let sampleBuffer = frame.sampleBuffer else {
      throw CameraError(message: "Cannot render a disposed frame.")
    }
    if layer.requiresFlushToResumeDecoding { layer.flush() }
    layer.enqueue(sampleBuffer)
    if layer.status == .failed {
      throw layer.error ?? CameraError(message: "Failed to render frame.")
    }
  }
}
