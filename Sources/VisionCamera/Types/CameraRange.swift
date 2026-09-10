// Copyright © 2025 Marc Rousavy @ Margelo

public struct CameraRange: Equatable, Sendable {
  public var min: Double
  public var max: Double

  public init(
    min: Double,
    max: Double
  ) {
    self.min = min
    self.max = max
  }
}
