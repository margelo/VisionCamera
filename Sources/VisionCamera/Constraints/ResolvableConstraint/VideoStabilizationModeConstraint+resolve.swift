// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation

extension VideoStabilizationModeConstraint: ResolvableConstraint {
  typealias ResolvedValue = TargetStabilizationMode

  func resolve(for format: AVCaptureDevice.Format) -> ConstraintResolution<TargetStabilizationMode> {
    return videoStabilizationMode.resolve(for: format)
  }
}
