// Copyright © 2025 Marc Rousavy @ Margelo

/// Represents the range of YUV color components.
///
/// Video range reserves sample values above and below the image range. Full range uses all available sample
/// values.
public enum ColorRange: CaseIterable, Sendable {
  /// The range of YUV color components is unknown.
  case unknown
  /// Limited Color Range. For 8-bit samples, Y ranges from 16 to 235 and UV ranges from 16 to 240.
  case video
  /// Full Color Range. Core Video 8-bit Y ranges from 0 to 255 and UV ranges from 1 to 255.
  case full

}
