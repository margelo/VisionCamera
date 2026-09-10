// Copyright © 2025 Marc Rousavy @ Margelo

public enum FocusReset: Equatable, Sendable {
  case never
  /// Return to the default metering mode after the specified number of seconds.
  case after(Double)
}
