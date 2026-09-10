// Copyright © 2025 Marc Rousavy @ Margelo

public struct PreviewStabilizationModeConstraint: Equatable, Sendable {
  public var previewStabilizationMode: TargetStabilizationMode

  public init(
    previewStabilizationMode: TargetStabilizationMode
  ) {
    self.previewStabilizationMode = previewStabilizationMode
  }
}
