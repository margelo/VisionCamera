// Copyright © 2025 Marc Rousavy @ Margelo

/// Configures the adaptiveness of the AE/AF/AWB pipeline after a metering operation has settled.
/// - ``SceneAdaptiveness/continuous``: Continuously keeps the target point relative
///   to the screen in focus, adapting AE/AF/AWB values if the subject area changes.
/// - ``SceneAdaptiveness/locked``: Keeps the AE/AF/AWB values locked in-place after
///   the metering operation has settled even if the subject area changes,
///   until focus is manually reset via ``CameraController/resetFocus()``
///   or another focus metering operation starts.
///
/// See ``CameraController/focus(at:options:)``
/// See ``FocusOptions``
public enum SceneAdaptiveness: CaseIterable, Sendable {
  /// Continuously keeps the target point relative to the screen in focus, adapting AE/AF/AWB values if the
  /// subject area changes.
  case continuous
  /// Keeps the AE/AF/AWB values locked in-place after the metering operation has settled even if the subject
  /// area changes, until focus is manually reset via ``CameraController/resetFocus()`` or another focus
  /// metering operation starts.
  case locked

}
