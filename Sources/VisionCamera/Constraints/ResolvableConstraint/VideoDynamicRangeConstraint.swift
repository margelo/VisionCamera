// Copyright © 2025 Marc Rousavy @ Margelo

/// A constraint to set ``TargetDynamicRange`` for Video
/// Streams (e.g. ``VideoOutput``).
///
/// ```swift
/// VideoDynamicRangeConstraint(
///   videoDynamicRange: TargetDynamicRange(
///     bitDepth: .hdr10Bit, colorSpace: .hlgBt2020, colorRange: .full))
/// ```
struct VideoDynamicRangeConstraint: Equatable, Sendable {
  /// The bit depth, color space, and component range to request for video.
  let videoDynamicRange: TargetDynamicRange

}
