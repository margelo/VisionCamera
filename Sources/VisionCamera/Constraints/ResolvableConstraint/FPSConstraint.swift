// Copyright © 2025 Marc Rousavy @ Margelo

/// A constraint to set a given frame rate for any Video,
/// Frame or Preview Streams (e.g. ``VideoOutput``,
/// ``FrameOutput``, or ``PreviewOutput``)
///
/// ```swift
/// FPSConstraint(fps: 60)
/// ```
struct FPSConstraint: Equatable, Sendable {
  /// The target frame rate, in frames per second.
  let fps: Double

}
