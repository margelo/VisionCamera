// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation

extension DynamicRangeBitDepth {
  func toTargetBitDepth() -> TargetDynamicRangeBitDepth {
    switch self {
    case .hdr10Bit:
      return .hdr10Bit
    case .sdr8Bit, .unknown:
      return .sdr8Bit
    }
  }
}
