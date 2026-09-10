// Copyright © 2025 Marc Rousavy @ Margelo

public enum AutoFocusSystem: String, CaseIterable, Sendable {
  case none
  case contrastDetection = "contrast-detection"
  case phaseDetection = "phase-detection"

  public var stringValue: String {
    rawValue
  }

  public init?(fromString string: String) {
    self.init(rawValue: string)
  }
}
