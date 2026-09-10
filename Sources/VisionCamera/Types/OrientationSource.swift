// Copyright © 2025 Marc Rousavy @ Margelo

/// Represents the source of a ``CameraOrientation``.
/// - ``OrientationSource/interface``: Uses the UI's orientation for setting output ``CameraOrientation``.
/// If screen orientation lock is on, the output orientation will also be locked to the screen's orientation.
/// - ``OrientationSource/device``: Uses the physical device's orientation for setting output ``CameraOrientation``.
/// Even if orientation lock is on, orientation will change when the device physically rotates.
public enum OrientationSource: CaseIterable, Sendable {
  /// Uses the UI's orientation for setting output ``CameraOrientation``. If screen orientation lock is on,
  /// the output orientation will also be locked to the screen's orientation.
  case interface
  /// Uses the physical device's orientation for setting output ``CameraOrientation``. Even if orientation
  /// lock is on, orientation will change when the device physically rotates.
  case device

}
