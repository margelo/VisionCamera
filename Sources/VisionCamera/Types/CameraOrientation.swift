// Copyright © 2025 Marc Rousavy @ Margelo

public enum CameraOrientation: String, CaseIterable, Sendable {
  case up
  case right
  case down
  case left

  public var stringValue: String {
    rawValue
  }

  public init?(fromString string: String) {
    self.init(rawValue: string)
  }
}
