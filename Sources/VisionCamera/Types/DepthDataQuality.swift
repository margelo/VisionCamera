// Copyright © 2025 Marc Rousavy @ Margelo

/// Describes the quality of a captured depth map.
public enum DepthDataQuality: CaseIterable, Sendable {
  /// The depth quality is unknown.
  case unknown
  /// The depth map has lower quality, for example because of difficult lighting.
  case low
  /// The depth map has high quality.
  case high

}
