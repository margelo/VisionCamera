// Copyright © 2025 Marc Rousavy @ Margelo

public enum QualityPrioritization: String, CaseIterable, Sendable {
  case speed
  case balanced
  case quality

  public var stringValue: String {
    rawValue
  }

  public init?(fromString string: String) {
    self.init(rawValue: string)
  }
}
