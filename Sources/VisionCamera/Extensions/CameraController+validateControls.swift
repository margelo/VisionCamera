// Copyright © 2026 Marc Rousavy @ Margelo

import AVFoundation

extension CameraController {
  static func validateTorchLevel(_ level: Float) throws {
    guard level == AVCaptureDevice.maxAvailableTorchLevel || (level.isFinite && level > 0 && level <= 1) else {
      throw CameraError(message: "The torch level must be greater than 0 and no greater than 1, or AVCaptureDevice.maxAvailableTorchLevel.")
    }
  }

  static func validateZoom(_ zoom: Double, rate: Double, range: ClosedRange<Double>) throws {
    guard zoom.isFinite, range.contains(zoom), rate.isFinite, rate > 0, Float(rate).isFinite else {
      throw CameraError(message: "The target zoom must be within the available range and the ramp rate must be finite and positive.")
    }
  }
}
