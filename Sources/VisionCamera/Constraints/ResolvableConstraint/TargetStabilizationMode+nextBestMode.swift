// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation

extension TargetStabilizationMode {
  func nextBestMode() -> TargetStabilizationMode {
    switch self {
    case .off:
      return .off
    case .auto:
      return .off
    case .standard:
      return .auto
    // Cinematic modes - don't fall back to low-latency modes
    case .cinematic:
      return .standard
    case .cinematicExtended:
      return .cinematic
    case .cinematicExtendedEnhanced:
      return .cinematicExtended
    // Low-latency modes - don't fall back to cinematic
    case .previewOptimized:
      return .standard
    case .lowLatency:
      return .previewOptimized
    }
  }

  /// Walks the fallback chain until we find a mode the format supports.
  /// Returns both the penalty (number of fallback steps) and the resolved mode.
  func resolve(for format: AVCaptureDevice.Format) -> ConstraintResolution<TargetStabilizationMode> {
    return resolve(isSupported: format.isVideoStabilizationModeSupported)
  }

  func resolve(isSupported: (AVCaptureVideoStabilizationMode) -> Bool) -> ConstraintResolution<TargetStabilizationMode> {
    var penalty = 0
    var currentMode = self
    while currentMode != .off {
      if let nativeMode = currentMode.toAVCaptureVideoStabilizationMode(), isSupported(nativeMode) {
        break
      }
      currentMode = currentMode.nextBestMode()
      penalty += 1
    }
    return ConstraintResolution(
      penalty: ConstraintPenalty(distance: Double(penalty)),
      resolvedValue: currentMode)
  }
}
