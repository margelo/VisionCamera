// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation

extension TargetStabilizationMode {
  func toAVCaptureVideoStabilizationMode() -> AVCaptureVideoStabilizationMode? {
    switch self {
    case .off:
      return .off
    case .auto:
      return .auto
    case .standard:
      return .standard
    case .cinematic:
      return .cinematic
    case .cinematicExtended:
      return .cinematicExtended
    case .cinematicExtendedEnhanced:
      guard #available(iOS 18.0, *) else { return nil }
      return .cinematicExtendedEnhanced
    case .previewOptimized:
      guard #available(iOS 17.0, *) else { return nil }
      return .previewOptimized
    case .lowLatency:
      guard #available(iOS 26.0, *) else { return nil }
      return .lowLatency
    }
  }
}
