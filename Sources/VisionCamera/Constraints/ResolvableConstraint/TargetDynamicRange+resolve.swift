// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation

extension TargetDynamicRange {
  /// Resolves the target dynamic range against the format's actual capabilities.
  /// Returns the achievable dynamic range (using format's actual bit depth + color range,
  /// and the best available color space from the fallback chain).
  func resolve(for format: AVCaptureDevice.Format) -> ConstraintResolution<TargetDynamicRange> {
    let actualBitDepth = format.formatDescription.mediaSubType.bitDepth
    let bitDepthPenalty = self.bitDepth.penalty(to: actualBitDepth)

    let colorSpaceResolution = self.colorSpace.resolve(for: format)

    let targetColorRange = self.colorRange.toColorRange()
    let actualColorRange = format.formatDescription.mediaSubType.colorRange
    let colorRangePenalty = targetColorRange.penalty(to: actualColorRange)

    let totalPenalty = Double(bitDepthPenalty + Int(colorSpaceResolution.penalty.distance) + colorRangePenalty)

    // Build the resolved dynamic range from what the format actually supports
    let resolvedDynamicRange = TargetDynamicRange(
      bitDepth: actualBitDepth.toTargetBitDepth(),
      colorSpace: colorSpaceResolution.resolvedValue,
      colorRange: actualColorRange.toTargetColorRange())

    return ConstraintResolution(
      penalty: ConstraintPenalty(distance: totalPenalty),
      resolvedValue: resolvedDynamicRange)
  }
}
