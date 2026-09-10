// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation

extension AVCaptureDevice.Format {
  func nearestFrameRateRange(containing targetFPS: Double) -> AVFrameRateRange {
    let nearestRange = self.videoSupportedFrameRateRanges.min { left, right in
      return left.penalty(for: targetFPS) < right.penalty(for: targetFPS)
    }
    guard let nearestRange else { fatalError("Device has no formats!") }
    return nearestRange
  }
}
