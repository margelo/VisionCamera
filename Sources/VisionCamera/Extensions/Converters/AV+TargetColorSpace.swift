// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation

extension TargetColorSpace {
  func toAVCaptureColorSpace() -> AVCaptureColorSpace? {
    switch self {
    case .srgb:
      return .sRGB
    case .p3D65:
      return .P3_D65
    case .hlgBt2020:
      return .HLG_BT2020
    case .appleLog:
      guard #available(iOS 17.0, *) else { return nil }
      return .appleLog
    case .appleLog2:
      guard #available(iOS 26.0, *) else { return nil }
      return .appleLog2
    }
  }
}
