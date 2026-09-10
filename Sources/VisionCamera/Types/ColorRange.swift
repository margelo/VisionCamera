// Copyright © 2025 Marc Rousavy @ Margelo

public enum ColorRange: String, CaseIterable, Sendable {
  case unknown
  case video
  case full

  public var stringValue: String {
    rawValue
  }

  public init?(fromString string: String) {
    self.init(rawValue: string)
  }
}
