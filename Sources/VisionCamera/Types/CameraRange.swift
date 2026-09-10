// Copyright © 2025 Marc Rousavy @ Margelo

/// Represents a numeric range with a minimum and maximum value, inclusive on both ends.
public struct CameraRange: Equatable, Sendable {
  /// The lower bound of the range, inclusive.
  public var min: Double
  /// The upper bound of the range, inclusive.
  public var max: Double

  /// Creates a range from its minimum and maximum values.
  ///
  /// - Parameters:
  ///   - min: The lower bound of the range, inclusive.
  ///   - max: The upper bound of the range, inclusive.
  public init(
    min: Double,
    max: Double
  ) {
    self.min = min
    self.max = max
  }
}
