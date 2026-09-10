// Copyright © 2025 Marc Rousavy @ Margelo

/// Chooses the native video format or requests an exact Core Video pixel layout.
///
/// A specific format must be available from the connected ``FrameOutput/output``.
/// ``CameraSession`` rejects unsupported formats during configuration.
public enum TargetVideoPixelFormat: Equatable, Sendable {
  /// Lets AVFoundation choose the native output format without requesting conversion.
  case native
  /// Requests an exact pixel format, including its component range and bit depth.
  ///
  /// Use `.pixelFormat(.yuv4208BitFull)` for full-range 8-bit YUV, or
  /// `.pixelFormat(.rgbBgra8Bit)` for BGRA. Custom ``PixelFormat`` values preserve Core Video identifiers.
  case pixelFormat(PixelFormat)
}
