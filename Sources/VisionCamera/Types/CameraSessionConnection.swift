// Copyright © 2025 Marc Rousavy @ Margelo

public struct CameraSessionConnection {
  public var input: CameraDeviceOrPosition
  public var outputs: [CameraOutputConfiguration]
  public var constraints: [Constraint]
  public var initialZoom: Double?
  public var initialExposureBias: Double?
  public var onSessionConfigSelected: ((_ config: CameraSessionConfig) -> Void)?

  public init(
    input: CameraDeviceOrPosition,
    outputs: [CameraOutputConfiguration],
    constraints: [Constraint] = [],
    initialZoom: Double? = nil,
    initialExposureBias: Double? = nil,
    onSessionConfigSelected: ((_ config: CameraSessionConfig) -> Void)? = nil
  ) {
    self.input = input
    self.outputs = outputs
    self.constraints = constraints
    self.initialZoom = initialZoom
    self.initialExposureBias = initialExposureBias
    self.onSessionConfigSelected = onSessionConfigSelected
  }
}
