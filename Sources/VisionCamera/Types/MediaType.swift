// Copyright © 2025 Marc Rousavy @ Margelo

public enum MediaType: String, CaseIterable, Sendable {
  case video
  case depth
  case metadata
  case other

  public var stringValue: String {
    rawValue
  }

  public init?(fromString string: String) {
    self.init(rawValue: string)
  }
}
