// Copyright © 2026 Marc Rousavy @ Margelo

import AVFoundation

extension CameraController {
  static func validateTorchLevel(_ level: Float) throws {
    guard level == AVCaptureDevice.maxAvailableTorchLevel || (level.isFinite && level > 0 && level <= 1) else {
      throw CameraControlError.invalidTorchLevel
    }
  }

  static func validateZoom(_ zoom: Double, rate: Double, range: ClosedRange<Double>) throws {
    guard zoom.isFinite, range.contains(zoom), rate.isFinite, rate > 0, Float(rate).isFinite else {
      throw CameraControlError.valueOutOfRange(parameter: .zoom, value: zoom, allowed: range)
    }
  }
}
