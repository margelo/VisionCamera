// Copyright © 2025 Marc Rousavy @ Margelo

public struct CameraControllerConfiguration: Equatable, Sendable {
  public var enableLowLightBoost: Bool?
  public var enableSmoothAutoFocus: Bool?
  public var enableDistortionCorrection: Bool?

  public init(
    enableLowLightBoost: Bool? = nil,
    enableSmoothAutoFocus: Bool? = nil,
    enableDistortionCorrection: Bool? = nil
  ) {
    self.enableLowLightBoost = enableLowLightBoost
    self.enableSmoothAutoFocus = enableSmoothAutoFocus
    self.enableDistortionCorrection = enableDistortionCorrection
  }
}
