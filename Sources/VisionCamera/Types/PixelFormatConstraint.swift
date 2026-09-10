// Copyright © 2025 Marc Rousavy @ Margelo

/// A constraint to prefer a streaming Format with
/// the given target ``PixelFormat``.
///
/// ```swift
/// PixelFormatConstraint(pixelFormat: .yuv4208BitFull)
/// ```
public struct PixelFormatConstraint: Equatable, Sendable {
  /// The streaming pixel format to prefer.
  public var pixelFormat: PixelFormat

  /// Creates a preferred pixel format for the Camera stream.
  ///
  /// - Parameters:
  ///   - pixelFormat: The streaming pixel format to prefer.
  public init(
    pixelFormat: PixelFormat
  ) {
    self.pixelFormat = pixelFormat
  }
}
