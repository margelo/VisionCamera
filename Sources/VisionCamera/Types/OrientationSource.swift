// Copyright © 2025 Marc Rousavy @ Margelo

public enum OrientationSource: String, CaseIterable, Sendable {
  case interface
  case device

  public var stringValue: String {
    rawValue
  }

  public init?(fromString string: String) {
    self.init(rawValue: string)
  }
}
