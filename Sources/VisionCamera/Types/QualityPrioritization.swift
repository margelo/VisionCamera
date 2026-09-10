// Copyright © 2025 Marc Rousavy @ Margelo

/// Specifies the prioritization between speed and quality for
/// photo capture.
/// - ``QualityPrioritization/speed``: Captures photos as fast as possible, possibly with zero-shutter-lag (ZSL).
/// - ``QualityPrioritization/balanced``: Usually the default, balances capture latency with quality.
/// - ``QualityPrioritization/quality``: Ensures photos are well exposed and allows enough time for maximum quality.
public enum QualityPrioritization: CaseIterable, Sendable {
  /// Captures photos as fast as possible, possibly with zero-shutter-lag (ZSL).
  case speed
  /// Usually the default, balances capture latency with quality.
  case balanced
  /// Ensures photos are well exposed and allows enough time for maximum quality.
  case quality

}
