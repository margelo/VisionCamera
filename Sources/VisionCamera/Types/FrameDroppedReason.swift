// Copyright © 2025 Marc Rousavy @ Margelo

public enum FrameDroppedReason: CaseIterable, Sendable {
  case unknown
  case frameWasLate
  case outOfBuffers
  case discontinuity
}
