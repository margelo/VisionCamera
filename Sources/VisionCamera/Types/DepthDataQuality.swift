// Copyright © 2025 Marc Rousavy @ Margelo

public enum DepthDataQuality: String, CaseIterable, Sendable {
  case unknown
  case low
  case high

  public var stringValue: String {
    rawValue
  }

  public init?(fromString string: String) {
    self.init(rawValue: string)
  }
}
