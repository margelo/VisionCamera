// Copyright © 2025 Marc Rousavy @ Margelo

public enum ExposureMode: String, CaseIterable, Sendable {
  case locked
  case autoExposure = "auto-exposure"
  case continuousAutoExposure = "continuous-auto-exposure"
  case custom

  public var stringValue: String {
    rawValue
  }

  public init?(fromString string: String) {
    self.init(rawValue: string)
  }
}
