// Copyright © 2025 Marc Rousavy @ Margelo

/// Represents the orientation, relative to a base anchor.
/// - ``CameraOrientation/up``: The default orientation relative to your base anchor. with no rotation at all.
/// - ``CameraOrientation/down``: Inverted upside down relative to your base anchor. Whatever was "top" before is now "bottom", whatever was "bottom" before is now "top".
/// - ``CameraOrientation/left``: Rotated 90° left. Whatever was "top" before is now "left", whatever was bottom before is now "right".
/// - ``CameraOrientation/right``: Rotated 90° right. Whatever was "top" before is now "right", whatever was bottom before is now "left".
public enum CameraOrientation: CaseIterable, Sendable {
  /// The default orientation relative to your base anchor. with no rotation at all.
  case up
  /// Rotated 90° right. Whatever was "top" before is now "right", whatever was bottom before is now "left".
  case right
  /// Inverted upside down relative to your base anchor. Whatever was "top" before is now "bottom", whatever
  /// was "bottom" before is now "top".
  case down
  /// Rotated 90° left. Whatever was "top" before is now "left", whatever was bottom before is now "right".
  case left

}
