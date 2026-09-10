// Copyright © 2025 Marc Rousavy @ Margelo

public struct WhiteBalanceGains: Equatable, Sendable {
  public var redGain: Double
  public var blueGain: Double
  public var greenGain: Double

  public init(
    redGain: Double,
    blueGain: Double,
    greenGain: Double
  ) {
    self.redGain = redGain
    self.blueGain = blueGain
    self.greenGain = greenGain
  }
}
