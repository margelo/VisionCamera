// Copyright © 2025 Marc Rousavy @ Margelo

/// Specifies the target bit depth of a video stream, either 8-bit or 10-bit.
public enum TargetDynamicRangeBitDepth: CaseIterable, Sendable {
  /// Uses 8 bits per component.
  case bit8
  /// Uses 10 bits per component.
  case bit10

}
