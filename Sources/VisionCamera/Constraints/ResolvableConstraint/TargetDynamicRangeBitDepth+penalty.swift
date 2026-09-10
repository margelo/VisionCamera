// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation

extension TargetDynamicRangeBitDepth {
  func penalty(to target: DynamicRangeBitDepth) -> Int {
    switch (self, target) {
    case (.bit8, .bit8), (.bit10, .bit10):
      return 0
    case (.bit8, .bit10):
      return 1
    case (.bit10, .bit8):
      return 2
    case (_, .unknown):
      return 3
    }
  }
}
