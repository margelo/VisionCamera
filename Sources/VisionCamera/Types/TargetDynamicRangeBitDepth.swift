// Copyright © 2025 Marc Rousavy @ Margelo

/// Specifies the target bit depth of a video stream, either 8-bit SDR or 10-bit HDR.
public enum TargetDynamicRangeBitDepth: CaseIterable, Sendable {
  /// Uses 8 bits per channel, often called "SDR".
  case sdr8Bit
  /// Uses 10 bits per channel, often called "HDR".
  case hdr10Bit

}
