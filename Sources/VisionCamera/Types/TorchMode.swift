// Copyright © 2025 Marc Rousavy @ Margelo

public enum TorchMode: String, CaseIterable, Sendable {
  case on
  case off

  public var stringValue: String {
    rawValue
  }

  public init?(fromString string: String) {
    self.init(rawValue: string)
  }
}
