// Copyright © 2025 Marc Rousavy @ Margelo

public struct WhiteBalanceTemperatureAndTint: Equatable, Sendable {
  public var temperature: Double
  public var tint: Double

  public init(
    temperature: Double,
    tint: Double
  ) {
    self.temperature = temperature
    self.tint = tint
  }
}
