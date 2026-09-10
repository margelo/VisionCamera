// Copyright © 2025 Marc Rousavy @ Margelo

public struct Size: Equatable, Sendable {
  public var width: Double
  public var height: Double

  public init(
    width: Double,
    height: Double
  ) {
    self.width = width
    self.height = height
  }
}
