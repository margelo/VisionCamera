// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation

extension VideoDynamicRangeConstraint: ResolvableConstraint {
  typealias ResolvedValue = DynamicRange

  func resolve(for format: AVCaptureDevice.Format) throws(CameraError) -> ConstraintResolution<DynamicRange> {
    return try videoDynamicRange.resolve(for: format)
  }
}
