// Copyright © 2025 Marc Rousavy @ Margelo

public enum DeviceType: String, CaseIterable, Sendable {
  case unknown
  case wideAngle = "wide-angle"
  case ultraWideAngle = "ultra-wide-angle"
  case telephoto
  case dual
  case dualWide = "dual-wide"
  case triple
  case quad
  case continuity
  case lidarDepth = "lidar-depth"
  case trueDepth = "true-depth"
  case timeOfFlightDepth = "time-of-flight-depth"
  case external

  public var stringValue: String {
    rawValue
  }

  public init?(fromString string: String) {
    self.init(rawValue: string)
  }
}
