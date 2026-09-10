// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation
import Foundation

struct ConstraintPenalty: Comparable, Equatable, Sendable {
  let distance: Double
  static func < (lhs: Self, rhs: Self) -> Bool {
    return lhs.distance < rhs.distance
  }
  static var noPenalty = ConstraintPenalty(distance: 0)
}
