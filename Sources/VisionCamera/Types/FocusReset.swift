// Copyright © 2025 Marc Rousavy @ Margelo

/// Specifies whether focus metering automatically returns to continuous focus after it settles.
public enum FocusReset: Equatable, Sendable {
  /// Keeps the metering configuration until focus is reset manually or another metering operation starts.
  case never
  /// Returns to continuous focus after metering has settled and the specified number of seconds has elapsed.
  /// The delay must be finite and nonnegative.
  case after(Double)
}
