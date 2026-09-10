// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation

extension PreviewStabilizationModeConstraint: ResolvableConstraint {
  typealias ResolvedValue = TargetStabilizationMode

  func resolve(for format: AVCaptureDevice.Format) -> ConstraintResolution<TargetStabilizationMode> {
    return previewStabilizationMode.resolve(for: format)
  }
}
