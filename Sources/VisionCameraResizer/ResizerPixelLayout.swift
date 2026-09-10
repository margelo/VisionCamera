// Copyright © 2025 Marc Rousavy @ Margelo

/// The arrangement of channels in a tightly packed output tensor.
public enum ResizerPixelLayout: UInt32, CaseIterable, Sendable {
  /// Complete pixels in row-major order, such as `RGBRGB`. This matches HWC or NHWC tensor storage.
  case interleaved = 0
  /// Three complete row-major channel planes, such as `RR...GG...BB...`. This matches CHW or NCHW tensor storage.
  case planar = 1
}
