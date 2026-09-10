// Copyright © 2025 Marc Rousavy @ Margelo

public enum SceneAdaptiveness: String, CaseIterable, Sendable {
  case continuous
  case locked

  public var stringValue: String {
    rawValue
  }

  public init?(fromString string: String) {
    self.init(rawValue: string)
  }
}
