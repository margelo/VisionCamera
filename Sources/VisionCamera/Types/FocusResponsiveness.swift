// Copyright © 2025 Marc Rousavy @ Margelo

/// Configures the responsiveness of a AE/AF/AWB focus operation.
/// - ``FocusResponsiveness/steady``: Steadily focuses to the specified point of
///   interest without disrupting. Most desirable for filming videos.
/// - ``FocusResponsiveness/snappy``: Snappily focuses to the specified point of
///   interest as fast as possible, possibly resetting focus.
///   Most desirable while not filming, or capturing photos.
///
/// See ``CameraController/focusTo(point:options:)``
/// See ``FocusOptions``
public enum FocusResponsiveness: CaseIterable, Sendable {
  /// Steadily focuses to the specified point of interest without disrupting. Most desirable for filming
  /// videos.
  case steady
  /// Snappily focuses to the specified point of interest as fast as possible, possibly resetting focus. Most
  /// desirable while not filming, or capturing photos.
  case snappy

}
