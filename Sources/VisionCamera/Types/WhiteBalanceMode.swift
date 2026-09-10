// Copyright © 2025 Marc Rousavy @ Margelo

public enum WhiteBalanceMode: String, CaseIterable, Sendable {
  case locked
  case autoWhiteBalance = "auto-white-balance"
  case continuousAutoWhiteBalance = "continuous-auto-white-balance"

  public var stringValue: String {
    rawValue
  }

  public init?(fromString string: String) {
    self.init(rawValue: string)
  }
}
