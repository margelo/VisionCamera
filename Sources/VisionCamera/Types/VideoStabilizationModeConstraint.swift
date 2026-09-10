// Copyright © 2025 Marc Rousavy @ Margelo

/// A constraint to set a ``TargetStabilizationMode`` for Video
/// Streams (e.g. ``VideoOutput``).
///
/// ```swift
/// VideoStabilizationModeConstraint(videoStabilizationMode: .cinematic)
/// ```
public struct VideoStabilizationModeConstraint: Equatable, Sendable {
  /// The stabilization mode to request for video streams.
  public var videoStabilizationMode: TargetStabilizationMode

  /// Creates a preferred stabilization mode for video streams.
  ///
  /// - Parameters:
  ///   - videoStabilizationMode: The stabilization mode to request for video streams.
  public init(
    videoStabilizationMode: TargetStabilizationMode
  ) {
    self.videoStabilizationMode = videoStabilizationMode
  }
}
