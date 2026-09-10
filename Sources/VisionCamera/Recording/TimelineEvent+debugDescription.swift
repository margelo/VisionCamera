// Copyright © 2025 Marc Rousavy @ Margelo

import CoreMedia
import Foundation

extension TimelineEvent: CustomDebugStringConvertible {
  var debugDescription: String {
    switch type {
    case .start:
      return "\(timestamp.seconds): ⏺️ Started"
    case .pause:
      return "\(timestamp.seconds): ⏸️ Paused"
    case .resume:
      return "\(timestamp.seconds): ▶️ Resumed"
    case .stop:
      return "\(timestamp.seconds): ⏹️ Stopped"
    }
  }
}
