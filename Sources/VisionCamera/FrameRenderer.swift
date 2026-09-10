import AVFoundation
import Foundation

public final class FrameRenderer {
  public let layer = AVSampleBufferDisplayLayer()

  public init() {}

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
