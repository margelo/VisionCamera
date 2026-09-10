// Copyright © 2025 Marc Rousavy @ Margelo

public enum TargetVideoPixelFormat: String, CaseIterable, Sendable {
  case native
  case yuv
  case rgb

  public var stringValue: String {
    rawValue
  }

  public init?(fromString string: String) {
    self.init(rawValue: string)
  }
}
