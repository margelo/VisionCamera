// Copyright © 2026 Marc Rousavy @ Margelo

extension Constraint {
  func isEquivalent(to other: Constraint) -> Bool {
    switch self {
    case .frameRate(let value):
      guard case .frameRate(let other) = other else { return false }
      return value == other
    case .videoStabilization(let value):
      guard case .videoStabilization(let other) = other else { return false }
      return value == other
    case .previewStabilization(let value):
      guard case .previewStabilization(let other) = other else { return false }
      return value == other
    case .resolution(let value):
      guard case .resolution(let other) = other else { return false }
      return value === other
    case .videoDynamicRange(let value):
      guard case .videoDynamicRange(let other) = other else { return false }
      return value == other
    case .pixelFormat(let value):
      guard case .pixelFormat(let other) = other else { return false }
      return value == other
    case .binned(let value):
      guard case .binned(let other) = other else { return false }
      return value == other
    }
  }
}
