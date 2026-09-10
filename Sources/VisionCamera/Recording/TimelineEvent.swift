// Copyright © 2025 Marc Rousavy @ Margelo

import CoreMedia
import Foundation

struct TimelineEvent {
  let type: EventType
  let timestamp: CMTime

  enum EventType {
    case start
    case pause
    case resume
    case stop
  }
}
