// Copyright © 2025 Marc Rousavy @ Margelo

/// Represents a Point in the current context's
/// coordinate system.
public struct Point: Equatable, Sendable {
  /// The X coordinate of the Point.
  public var x: Double
  /// The Y coordinate of the Point.
  public var y: Double

  /// Creates a point from its horizontal and vertical coordinates.
  ///
  /// - Parameters:
  ///   - x: The X coordinate of the Point.
  ///   - y: The Y coordinate of the Point.
  public init(
    x: Double,
    y: Double
  ) {
    self.x = x
    self.y = y
  }
}
