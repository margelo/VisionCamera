// Copyright © 2025 Marc Rousavy @ Margelo

public enum TargetColorSpace: String, CaseIterable, Sendable {
  case srgb
  case dolbyVision = "dolby-vision"
  case p3D65 = "p3-d65"
  case hlgBt2020 = "hlg-bt2020"
  case appleLog = "apple-log"
  case appleLog2 = "apple-log-2"

  public var stringValue: String {
    rawValue
  }

  public init?(fromString string: String) {
    self.init(rawValue: string)
  }
}
