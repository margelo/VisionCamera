// Copyright © 2025 Marc Rousavy @ Margelo

/// Represents the bit-depth of a ``DynamicRange``.
///
/// - ``DynamicRangeBitDepth/sdr8Bit``: Uses 8 bits per channel, often called "SDR"
/// - ``DynamicRangeBitDepth/hdr10Bit``: Uses 10 bits per channel, often called "HDR"
public enum DynamicRangeBitDepth: CaseIterable, Sendable {
  /// Uses 8 bits per channel, often called "SDR".
  case sdr8Bit
  /// Uses 10 bits per channel, often called "HDR".
  case hdr10Bit
  /// The value is unknown.
  case unknown

}
