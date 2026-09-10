// Copyright © 2025 Marc Rousavy @ Margelo

/// A constraint to set a given frame rate for any Video,
/// Frame or Preview Streams (e.g. ``VideoOutput``,
/// ``FrameOutput``, or ``PreviewOutput``)
///
/// ```swift
/// FPSConstraint(fps: 60)
/// ```
public struct FPSConstraint: Equatable, Sendable {
  /// The target frame rate, in frames per second.
  public var fps: Double

  /// Creates a preferred frame rate, in frames per second.
  ///
  /// - Parameters:
  ///   - fps: The target frame rate, in frames per second.
  public init(
    fps: Double
  ) {
    self.fps = fps
  }
}
