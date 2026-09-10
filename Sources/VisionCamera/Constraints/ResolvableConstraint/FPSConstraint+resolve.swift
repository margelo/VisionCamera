// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation

extension FPSConstraint: ResolvableConstraint {
  typealias ResolvedValue = Double

  func resolve(for format: AVCaptureDevice.Format) -> ConstraintResolution<Double> {
    let nearestRange = format.nearestFrameRateRange(containing: fps)
    let penalty = nearestRange.penalty(for: fps)
    let clampedFPS = min(max(fps, nearestRange.minFrameRate), nearestRange.maxFrameRate)
    return ConstraintResolution(
      penalty: ConstraintPenalty(distance: penalty),
      resolvedValue: clampedFPS)
  }
}
