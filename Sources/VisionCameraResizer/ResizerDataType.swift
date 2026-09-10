// Copyright © 2025 Marc Rousavy @ Margelo

/// The scalar encoding of a resized color channel.
public enum ResizerDataType: CaseIterable, Sendable {
  /// Unsigned 8-bit values in `0...255`, rounded to the nearest integer.
  case uint8
  /// Signed 8-bit values computed as the unsigned value minus 128, in `-128...127`.
  case int8
  /// IEEE 754 half-precision values in `0...1`.
  case float16
  /// IEEE 754 single-precision values in `0...1`.
  case float32

  /// The number of bytes per color channel.
  public var bytesPerChannel: Int {
    switch self {
    case .uint8, .int8: return 1
    case .float16: return 2
    case .float32: return 4
    }
  }
}
