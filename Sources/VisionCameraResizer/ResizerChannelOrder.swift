// Copyright © 2025 Marc Rousavy @ Margelo

/// The order of the three channels in a resized image.
public enum ResizerChannelOrder: UInt32, CaseIterable, Sendable {
  /// Red, green, then blue.
  case rgb = 0
  /// Blue, green, then red.
  case bgr = 1
}
