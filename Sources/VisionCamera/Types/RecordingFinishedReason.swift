// Copyright © 2025 Marc Rousavy @ Margelo

public enum RecordingFinishedReason: CaseIterable, Sendable {
  case stopped
  case maxDurationReached
  case maxFileSizeReached
}
