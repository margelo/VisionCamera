// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation

extension TargetDynamicRangeBitDepth {
  func penalty(to target: DynamicRangeBitDepth) -> Int {
    switch (self, target) {
    case (.sdr8Bit, .sdr8Bit), (.hdr10Bit, .hdr10Bit):
      return 0
    case (.sdr8Bit, .hdr10Bit):
      return 1
    case (.hdr10Bit, .sdr8Bit):
      return 2
    case (_, .unknown):
      return 3
    }
  }
}
