// Copyright © 2025 Marc Rousavy @ Margelo

public enum DepthDataAccuracy: String, CaseIterable, Sendable {
  case unknown
  case relative
  case absolute

  public var stringValue: String {
    rawValue
  }

  public init?(fromString string: String) {
    self.init(rawValue: string)
  }
}
