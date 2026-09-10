// Copyright © 2025 Marc Rousavy @ Margelo

/// Represents the white balance mode of a ``CameraDevice``.
/// - ``WhiteBalanceMode/locked``: The white balance is locked at its current value and does not adapt to scene changes.
/// - ``WhiteBalanceMode/autoWhiteBalance``: The white balance is adjusted once to match the current scene.
/// - ``WhiteBalanceMode/continuousAutoWhiteBalance``: The white balance is continuously adjusted as the scene changes.
public enum WhiteBalanceMode: CaseIterable, Sendable {
  /// The white balance is locked at its current value and does not adapt to scene changes.
  case locked
  /// The white balance is adjusted once to match the current scene.
  case autoWhiteBalance
  /// The white balance is continuously adjusted as the scene changes.
  case continuousAutoWhiteBalance

}
