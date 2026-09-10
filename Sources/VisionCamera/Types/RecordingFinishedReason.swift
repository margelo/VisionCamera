// Copyright © 2025 Marc Rousavy @ Margelo

public enum RecordingFinishedReason: String, CaseIterable, Sendable {
  case stopped
  case maxDurationReached = "max-duration-reached"
  case maxFileSizeReached = "max-file-size-reached"

  public var stringValue: String {
    rawValue
  }

  public init?(fromString string: String) {
    self.init(rawValue: string)
  }
}
