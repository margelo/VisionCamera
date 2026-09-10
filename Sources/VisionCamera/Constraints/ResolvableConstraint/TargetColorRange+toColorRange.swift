// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation

extension TargetColorRange {
  func toColorRange() -> ColorRange {
    switch self {
    case .video:
      return .video
    case .full:
      return .full
    }
  }
}
