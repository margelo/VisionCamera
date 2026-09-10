// Copyright © 2025 Marc Rousavy @ Margelo

/// Represents a white balance setting expressed as a color temperature and tint offset.
///
/// This is a human-friendly way of expressing white balance compared to raw
/// ``WhiteBalanceGains``.
///
/// See ``WhiteBalanceGains``
public struct WhiteBalanceTemperatureAndTint: Equatable, Sendable {
  /// The color temperature in Kelvin (e.g. `5500` for daylight, `3200` for tungsten).
  public var temperature: Double
  /// The green/magenta tint offset away from the temperature's black-body curve.
  /// Positive values shift towards magenta, negative values shift towards green.
  public var tint: Double

  /// Creates a white-balance setting from its color temperature and tint offset.
  ///
  /// - Parameters:
  ///   - temperature: The color temperature in Kelvin (e.g. `5500` for daylight, `3200` for tungsten).
  ///   - tint: The green/magenta tint offset away from the temperature's black-body curve. Positive values shift towards magenta, negative values shift towards green.
  public init(
    temperature: Double,
    tint: Double
  ) {
    self.temperature = temperature
    self.tint = tint
  }
}
