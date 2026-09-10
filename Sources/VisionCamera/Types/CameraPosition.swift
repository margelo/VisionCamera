// Copyright © 2025 Marc Rousavy @ Margelo

public enum CameraPosition: String, CaseIterable, Sendable {
  case external
  case front
  case back
  case unspecified

  public var stringValue: String {
    rawValue
  }

  public init?(fromString string: String) {
    self.init(rawValue: string)
  }
}
