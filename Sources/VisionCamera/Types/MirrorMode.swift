// Copyright © 2025 Marc Rousavy @ Margelo

public enum MirrorMode: String, CaseIterable, Sendable {
  case on
  case off
  case auto

  public var stringValue: String {
    rawValue
  }

  public init?(fromString string: String) {
    self.init(rawValue: string)
  }
}
