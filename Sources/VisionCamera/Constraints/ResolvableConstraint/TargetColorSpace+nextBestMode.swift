// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation

extension TargetColorSpace {
  func nextBestMode() -> TargetColorSpace {
    switch self {
    case .srgb:
      return .srgb
    case .p3D65:
      return .srgb
    case .hlgBt2020:
      return .p3D65
    case .appleLog:
      return .hlgBt2020
    case .appleLog2:
      return .appleLog
    case .dolbyVision:
      // Dolby Vision is not supported on iOS
      return .hlgBt2020
    }
  }

  /// Walks the color space fallback chain until we find one the format supports.
  /// Returns both the penalty (number of fallback steps) and the resolved color space.
  func resolve(for format: AVCaptureDevice.Format) -> ConstraintResolution<TargetColorSpace> {
    var penalty = 0
    var currentColorSpace = self
    while currentColorSpace != .srgb {
      if format.supportedColorSpaces.contains(currentColorSpace.toAVCaptureColorSpace()) {
        break
      }
      currentColorSpace = currentColorSpace.nextBestMode()
      penalty += 1
    }
    return ConstraintResolution(
      penalty: ConstraintPenalty(distance: Double(penalty)),
      resolvedValue: currentColorSpace)
  }
}
