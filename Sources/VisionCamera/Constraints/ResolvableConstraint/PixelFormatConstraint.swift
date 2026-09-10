// Copyright © 2025 Marc Rousavy @ Margelo

/// A constraint to prefer a streaming Format with
/// the given target ``PixelFormat``.
///
/// ```swift
/// PixelFormatConstraint(pixelFormat: .yuv4208BitFull)
/// ```
struct PixelFormatConstraint: Equatable, Sendable {
  /// The streaming pixel format to prefer.
  let pixelFormat: PixelFormat

}
