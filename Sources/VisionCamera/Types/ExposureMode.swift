// Copyright © 2025 Marc Rousavy @ Margelo

/// Represents the exposure mode of a ``CameraDevice``.
/// - ``ExposureMode/locked``: The exposure is locked at its current value and does not adapt to scene changes.
/// - ``ExposureMode/autoExposure``: The exposure is adjusted once to a suitable value for the current scene.
/// - ``ExposureMode/continuousAutoExposure``: The exposure is continuously adjusted as the scene changes.
/// - ``ExposureMode/custom``: The exposure is manually controlled via custom ISO and shutter speed.
public enum ExposureMode: CaseIterable, Sendable {
  /// The exposure is locked at its current value and does not adapt to scene changes.
  case locked
  /// The exposure is adjusted once to a suitable value for the current scene.
  case autoExposure
  /// The exposure is continuously adjusted as the scene changes.
  case continuousAutoExposure
  /// The exposure is manually controlled via custom ISO and shutter speed.
  case custom

}
