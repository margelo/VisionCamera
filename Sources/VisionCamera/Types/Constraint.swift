// Copyright © 2025 Marc Rousavy @ Margelo

/// Constraints are session configuration options that are negotiated by
/// the ``CameraSession`` to find a closest-matching working
/// Camera configuration.
///
/// In other words, Constraints describe _intent_.
///
/// See ``CameraSessionConnection/constraints``
///
/// Earlier constraints have higher priority during format negotiation.
///
/// ```swift
/// let constraints: [Constraint] = [
///   .fps(FPSConstraint(fps: 60)),
///   .videoStabilizationMode(
///     VideoStabilizationModeConstraint(videoStabilizationMode: .cinematicExtended)),
/// ]
/// ```
public enum Constraint {
  /// Requests a frame rate for video, frame, and preview streams.
  case fps(FPSConstraint)
  /// Requests a stabilization mode for video streams.
  case videoStabilizationMode(VideoStabilizationModeConstraint)
  /// Requests a stabilization mode for the preview.
  case previewStabilizationMode(PreviewStabilizationModeConstraint)
  /// Prioritizes an output's target resolution during format negotiation.
  case resolutionBias(ResolutionBiasConstraint)
  /// Requests a dynamic range for video streams.
  case videoDynamicRange(VideoDynamicRangeConstraint)
  /// Expresses a preference for photo HDR. This preference has no effect in the iOS resolver.
  case photoHDR(PhotoHDRConstraint)
  /// Prefers a streaming format with the requested pixel format.
  case pixelFormat(PixelFormatConstraint)
  /// Prefers a binned or non-binned sensor format.
  case binned(BinnedConstraint)
}
