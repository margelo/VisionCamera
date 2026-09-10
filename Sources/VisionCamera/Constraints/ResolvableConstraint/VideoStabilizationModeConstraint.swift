// Copyright © 2025 Marc Rousavy @ Margelo

/// A constraint to set a ``TargetStabilizationMode`` for Video
/// Streams (e.g. ``VideoOutput``).
///
/// ```swift
/// VideoStabilizationModeConstraint(videoStabilizationMode: .cinematic)
/// ```
struct VideoStabilizationModeConstraint: Equatable, Sendable {
  /// The stabilization mode to request for video streams.
  let videoStabilizationMode: TargetStabilizationMode

}
