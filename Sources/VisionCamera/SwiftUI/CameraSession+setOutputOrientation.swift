// Copyright © 2026 Marc Rousavy @ Margelo

extension CameraSession {
  func setOutputOrientation(_ orientation: CameraOrientation, outputs: [any CameraOutput]) async {
    await Self.queue.perform {
      for output in outputs { output.outputOrientation = orientation }
    }
  }
}
