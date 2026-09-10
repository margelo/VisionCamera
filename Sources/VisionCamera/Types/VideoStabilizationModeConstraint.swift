// Copyright © 2025 Marc Rousavy @ Margelo

public struct VideoStabilizationModeConstraint: Equatable, Sendable {
  public var videoStabilizationMode: TargetStabilizationMode

  public init(
    videoStabilizationMode: TargetStabilizationMode
  ) {
    self.videoStabilizationMode = videoStabilizationMode
  }
}
