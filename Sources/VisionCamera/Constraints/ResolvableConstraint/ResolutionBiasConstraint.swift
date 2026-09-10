// Copyright © 2025 Marc Rousavy @ Margelo

/// A constraint to bias the resolution of the given ``CameraOutput``
/// over other constraints.
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
/// For photo resolution to take priority over video resolution:
///
/// ```swift
/// let constraints: [Constraint] = [
///   .resolution(photoOutput),
///   .resolution(videoOutput),
/// ]
/// ```
struct ResolutionBiasConstraint {
  /// The output whose target resolution should influence format negotiation.
  let resolutionBias: any CameraOutput

}
