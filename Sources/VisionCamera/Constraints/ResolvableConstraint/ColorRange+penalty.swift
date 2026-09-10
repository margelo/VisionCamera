// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation

extension ColorRange {
  func penalty(to target: ColorRange) -> Int {
    switch (self, target) {
    case (.video, .video), (.full, .full):
      return 0
    case (.video, .full):
      return 1
    case (.full, .video):
      return 2
    case (_, .unknown), (.unknown, _):
      return 3
    }
  }

  func toTargetColorRange() -> TargetColorRange {
    switch self {
    case .full:
      return .full
    case .video, .unknown:
      return .video
    }
  }
}
