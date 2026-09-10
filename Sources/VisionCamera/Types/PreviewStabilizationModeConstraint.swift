// Copyright © 2025 Marc Rousavy @ Margelo

/// A constraint to set a ``TargetStabilizationMode`` for Preview
/// Streams (e.g. ``PreviewOutput``).
///
/// ```swift
/// PreviewStabilizationModeConstraint(previewStabilizationMode: .previewOptimized)
/// ```
public struct PreviewStabilizationModeConstraint: Equatable, Sendable {
  /// The stabilization mode to request for preview streams.
  public var previewStabilizationMode: TargetStabilizationMode

  /// Creates a preferred stabilization mode for preview streams.
  ///
  /// - Parameters:
  ///   - previewStabilizationMode: The stabilization mode to request for preview streams.
  public init(
    previewStabilizationMode: TargetStabilizationMode
  ) {
    self.previewStabilizationMode = previewStabilizationMode
  }
}
