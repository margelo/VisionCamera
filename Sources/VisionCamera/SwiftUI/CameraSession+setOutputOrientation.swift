// Copyright © 2026 Marc Rousavy @ Margelo

extension CameraSession {
  func setOutputOrientation(_ orientation: CameraOrientation, outputs: [any CameraOutput]) async {
    await Self.queue.perform {
      for output in outputs {
        switch output {
        case let output as PhotoOutput: output.outputOrientation = orientation
        case let output as any VideoOutput: output.outputOrientation = orientation
        case let output as FrameOutput: output.outputOrientation = orientation
        case let output as DepthOutput: output.outputOrientation = orientation
        default: break
        }
      }
    }
  }
}
