// Copyright © 2025 Marc Rousavy @ Margelo

/// Represents the target mirroring setting for a Camera Output.
/// - ``MirrorMode/on``: Mirrors the Camera, e.g. for front Cameras.
/// - ``MirrorMode/off``: Doesn't mirror anything.
/// - ``MirrorMode/auto``: Automatically mirrors the Camera if the platform recommends it, such as for front Cameras.
public enum MirrorMode: CaseIterable, Sendable {
  /// Mirrors the Camera, e.g. for front Cameras.
  case on
  /// Doesn't mirror anything.
  case off
  /// Automatically mirrors the Camera if the platform recommends it, such as for front Cameras.
  case auto

}
