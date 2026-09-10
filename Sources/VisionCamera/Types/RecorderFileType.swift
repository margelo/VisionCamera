// Copyright © 2025 Marc Rousavy @ Margelo

public enum RecorderFileType: String, CaseIterable, Sendable {
  case mp4
  case mov

  public var stringValue: String {
    rawValue
  }

  public init?(fromString string: String) {
    self.init(rawValue: string)
  }
}
