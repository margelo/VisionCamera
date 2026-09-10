// Copyright © 2025 Marc Rousavy @ Margelo

/// Represents the focus mode of a ``CameraDevice``.
/// - ``FocusMode/locked``: The lens position is locked at its current value and does not adapt to scene changes.
/// - ``FocusMode/autoFocus``: The lens is adjusted once to focus the current scene.
/// - ``FocusMode/continuousAutoFocus``: The lens is continuously adjusted as the scene changes.
public enum FocusMode: CaseIterable, Sendable {
  /// The lens position is locked at its current value and does not adapt to scene changes.
  case locked
  /// The lens is adjusted once to focus the current scene.
  case autoFocus
  /// The lens is continuously adjusted as the scene changes.
  case continuousAutoFocus

}
