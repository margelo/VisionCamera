// Copyright © 2025 Marc Rousavy @ Margelo

public enum DeviceType: CaseIterable, Sendable {
  case unknown
  case wideAngle
  case ultraWideAngle
  case telephoto
  case dual
  case dualWide
  case triple
  case quad
  case continuity
  case lidarDepth
  case trueDepth
  case timeOfFlightDepth
  case external
}
