// Copyright © 2025 Marc Rousavy @ Margelo

public enum TargetColorRange: String, CaseIterable, Sendable {
  case video
  case full

  public var stringValue: String {
    rawValue
  }

  public init?(fromString string: String) {
    self.init(rawValue: string)
  }
}
