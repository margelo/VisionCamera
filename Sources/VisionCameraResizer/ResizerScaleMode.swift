// Copyright © 2025 Marc Rousavy @ Margelo

/// The mapping used when the upright input and the output have different aspect ratios.
public enum ResizerScaleMode: UInt32, CaseIterable, Sendable {
  /// Preserves aspect ratio and fills the output with a centered crop.
  case cover = 0
  /// Preserves aspect ratio and pads unused output pixels with black.
  case contain = 1
  /// Stretches each axis independently to fill the output.
  case stretch = 2
}
