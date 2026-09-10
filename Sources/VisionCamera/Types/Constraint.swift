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
///   .frameRate(60),
///   .videoStabilization(.cinematicExtended),
/// ]
/// ```
public enum Constraint {
  /// Requests a frame rate for video, frame, and preview streams.
  case frameRate(Double)
  /// Requests a stabilization mode for video streams.
  case videoStabilization(TargetStabilizationMode)
  /// Requests a stabilization mode for the preview.
  case previewStabilization(TargetStabilizationMode)
  /// Prioritizes an output's target resolution during format negotiation.
  ///
  /// The resolution bias goes both ways; for example, if the given
  /// ``CameraOutput``'s resolution is very low, a Camera
  /// configuration most closely matching that low resolution will
  /// be used.
  ///
  /// If there are two resolution bias constraints, one with a very
  /// high, and one with a very low output target resolution, a
  /// good "middle-ground" will be chosen.
  ///
  /// For outputs with an explicit target resolution (e.g.
  /// ``VideoOutput`` or ``PhotoOutput``),
  /// resolution negotiation prefers aspect ratio matches
  /// over raw pixel count differences first, then uses a
  /// logarithmic scale to compare resolution differences.
  /// A ``PreviewOutput`` instead only prefers
  /// Formats at least as large as the screen, ignoring
  /// aspect ratio (it fills the screen either way).
  ///
  case resolution(any CameraOutput)
  /// Requests a dynamic range for video streams.
  case videoDynamicRange(TargetDynamicRange)
  /// Expresses a preference for photo HDR. This preference has no effect in the iOS resolver.
  case photoHDR(Bool)
  /// Prefers a streaming format with the requested pixel format.
  case pixelFormat(PixelFormat)
  /// Prefers a binned or non-binned sensor format.
  case binned(Bool)
}
