// Copyright © 2025 Marc Rousavy @ Margelo

/// Specifies the range of YUV color components to request during format negotiation.
public enum TargetColorRange: CaseIterable, Sendable {
  /// Limited Color Range. For 8-bit samples, Y ranges from 16 to 235 and UV ranges from 16 to 240.
  case video
  /// Full Color Range. For 8-bit samples, both Y and UV range from 0 to 255.
  case full

}
