// Copyright © 2025 Marc Rousavy @ Margelo

public struct ResolutionBiasConstraint {
  public var resolutionBias: any CameraOutput

  public init(
    resolutionBias: any CameraOutput
  ) {
    self.resolutionBias = resolutionBias
  }
}
