// Copyright © 2025 Marc Rousavy @ Margelo

public enum FocusResponsiveness: String, CaseIterable, Sendable {
  case steady
  case snappy

  public var stringValue: String {
    rawValue
  }

  public init?(fromString string: String) {
    self.init(rawValue: string)
  }
}
