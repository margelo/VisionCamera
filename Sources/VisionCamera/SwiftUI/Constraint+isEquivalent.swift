// Copyright © 2026 Marc Rousavy @ Margelo

extension Constraint {
  func isEquivalent(to other: Constraint) -> Bool {
    switch self {
    case .fps(let value):
      guard case .fps(let other) = other else { return false }
      return value == other
    case .videoStabilizationMode(let value):
      guard case .videoStabilizationMode(let other) = other else { return false }
      return value == other
    case .previewStabilizationMode(let value):
      guard case .previewStabilizationMode(let other) = other else { return false }
      return value == other
    case .resolutionBias(let value):
      guard case .resolutionBias(let other) = other else { return false }
      return value.resolutionBias === other.resolutionBias
    case .videoDynamicRange(let value):
      guard case .videoDynamicRange(let other) = other else { return false }
      return value == other
    case .photoHDR(let value):
      guard case .photoHDR(let other) = other else { return false }
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
