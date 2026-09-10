// Copyright © 2025 Marc Rousavy @ Margelo

/// Represents a 2D size in pixels.
public struct Size: Equatable, Sendable {
  /// The width, in pixels.
  public var width: Double
  /// The height, in pixels.
  public var height: Double

  /// Creates a size from its width and height.
  ///
  /// - Parameters:
  ///   - width: The width, in pixels.
  ///   - height: The height, in pixels.
  public init(
    width: Double,
    height: Double
  ) {
    self.width = width
    self.height = height
  }
}
