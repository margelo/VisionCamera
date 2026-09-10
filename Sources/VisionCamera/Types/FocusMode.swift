// Copyright © 2025 Marc Rousavy @ Margelo

public enum FocusMode: String, CaseIterable, Sendable {
  case locked
  case autoFocus = "auto-focus"
  case continuousAutoFocus = "continuous-auto-focus"

  public var stringValue: String {
    rawValue
  }

  public init?(fromString string: String) {
    self.init(rawValue: string)
  }
}
