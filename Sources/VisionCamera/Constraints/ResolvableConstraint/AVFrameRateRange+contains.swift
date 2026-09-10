// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation

extension AVFrameRateRange {
  func contains(fps: Double) -> Bool {
    return fps >= self.minFrameRate && fps <= self.maxFrameRate
  }
  func penalty(for fps: Double) -> Double {
    if self.contains(fps: fps) {
      return 0.0
    } else {
      let undershoot = self.minFrameRate - fps
      let overshoot = fps - self.maxFrameRate
      return max(undershoot, overshoot)
    }
  }
}
