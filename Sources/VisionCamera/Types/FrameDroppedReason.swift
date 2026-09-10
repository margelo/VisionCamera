// Copyright © 2025 Marc Rousavy @ Margelo

public enum FrameDroppedReason: String, CaseIterable, Sendable {
  case unknown
  case frameWasLate = "frame-was-late"
  case outOfBuffers = "out-of-buffers"
  case discontinuity

  public var stringValue: String {
    rawValue
  }

  public init?(fromString string: String) {
    self.init(rawValue: string)
  }
}
