// Copyright © 2025 Marc Rousavy @ Margelo

/// A constraint to set ``TargetDynamicRange`` for Video
/// Streams (e.g. ``VideoOutput``).
///
/// ```swift
/// VideoDynamicRangeConstraint(
///   videoDynamicRange: TargetDynamicRange(
///     bitDepth: .hdr10Bit, colorSpace: .hlgBt2020, colorRange: .full))
/// ```
public struct VideoDynamicRangeConstraint: Equatable, Sendable {
  /// The bit depth, color space, and component range to request for video.
  public var videoDynamicRange: TargetDynamicRange

  /// Creates a preferred dynamic range for video streams.
  ///
  /// - Parameters:
  ///   - videoDynamicRange: The bit depth, color space, and component range to request for video.
  public init(
    videoDynamicRange: TargetDynamicRange
  ) {
    self.videoDynamicRange = videoDynamicRange
  }
}
