// Copyright © 2025 Marc Rousavy @ Margelo

public struct VideoDynamicRangeConstraint: Equatable, Sendable {
  public var videoDynamicRange: TargetDynamicRange

  public init(
    videoDynamicRange: TargetDynamicRange
  ) {
    self.videoDynamicRange = videoDynamicRange
  }
}
