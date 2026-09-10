// Copyright © 2025 Marc Rousavy @ Margelo

/// A constraint to set a ``TargetStabilizationMode`` for Preview
/// Streams (e.g. ``PreviewOutput``).
///
/// ```swift
/// PreviewStabilizationModeConstraint(previewStabilizationMode: .previewOptimized)
/// ```
struct PreviewStabilizationModeConstraint: Equatable, Sendable {
  /// The stabilization mode to request for preview streams.
  let previewStabilizationMode: TargetStabilizationMode

}
