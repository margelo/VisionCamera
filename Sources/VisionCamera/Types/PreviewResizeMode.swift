// Copyright © 2025 Marc Rousavy @ Margelo

public enum PreviewResizeMode: String, CaseIterable, Sendable {
  case cover
  case contain

  public var stringValue: String {
    rawValue
  }

  public init?(fromString string: String) {
    self.init(rawValue: string)
  }
}
