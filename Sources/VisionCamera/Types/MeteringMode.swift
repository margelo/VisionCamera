// Copyright © 2025 Marc Rousavy @ Margelo

public enum MeteringMode: String, CaseIterable, Sendable {
  case ae = "AE"
  case af = "AF"
  case awb = "AWB"

  public var stringValue: String {
    rawValue
  }

  public init?(fromString string: String) {
    self.init(rawValue: string)
  }
}
