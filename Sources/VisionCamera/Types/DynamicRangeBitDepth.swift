// Copyright © 2025 Marc Rousavy @ Margelo

/// Represents the component bit depth of a ``DynamicRange``.
///
/// Bit depth does not determine the transfer function or whether a stream contains HDR video.
///
/// - ``DynamicRangeBitDepth/bit8``: Uses 8 bits per component
/// - ``DynamicRangeBitDepth/bit10``: Uses 10 bits per component
public enum DynamicRangeBitDepth: CaseIterable, Sendable {
  /// Uses 8 bits per component.
  case bit8
  /// Uses 10 bits per component.
  case bit10
  /// The value is unknown.
  case unknown

}
