// Copyright © 2025 Marc Rousavy @ Margelo

/// Describes whether a depth map provides absolute measurements or relative depth values.
public enum DepthDataAccuracy: CaseIterable, Sendable {
  /// The accuracy of the depth values is unknown.
  case unknown
  /// Values describe relative depth, and may have a scale error.
  case relative
  /// Values represent absolute distances in the scene.
  case absolute

}
