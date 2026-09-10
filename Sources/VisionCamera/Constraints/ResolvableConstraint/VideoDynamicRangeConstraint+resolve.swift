// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation

extension VideoDynamicRangeConstraint: ResolvableConstraint {
  typealias ResolvedValue = TargetDynamicRange

  func resolve(for format: AVCaptureDevice.Format) -> ConstraintResolution<TargetDynamicRange> {
    return videoDynamicRange.resolve(for: format)
  }
}
