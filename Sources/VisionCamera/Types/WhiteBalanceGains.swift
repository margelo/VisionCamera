// Copyright © 2025 Marc Rousavy @ Margelo

/// Represents the per-channel gains applied for white balance correction.
///
/// Each gain is a multiplier applied to the respective color channel in the
/// Camera's raw sensor data to achieve a neutral white point.
///
/// See ``WhiteBalanceTemperatureAndTint``
public struct WhiteBalanceGains: Equatable, Sendable {
  /// The gain applied to the red channel.
  public var redGain: Double
  /// The gain applied to the blue channel.
  public var blueGain: Double
  /// The gain applied to the green channel.
  public var greenGain: Double

  /// Creates white-balance multipliers for the red, blue, and green channels.
  ///
  /// - Parameters:
  ///   - redGain: The gain applied to the red channel.
  ///   - blueGain: The gain applied to the blue channel.
  ///   - greenGain: The gain applied to the green channel.
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
