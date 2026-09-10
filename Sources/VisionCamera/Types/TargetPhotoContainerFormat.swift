// Copyright © 2025 Marc Rousavy @ Margelo

/// The encoded format and compression quality requested for a photo capture.
public enum TargetPhotoContainerFormat: Equatable, Sendable {
  /// Captures JPEG with a compression quality from `0.0` to `1.0`.
  case jpeg(quality: Double = 0.9)
  /// Captures HEIC with a compression quality from `0.0` to `1.0`.
  case heic(quality: Double = 0.9)
  /// Captures a RAW photo in a Digital Negative container.
  case dng
  /// Selects HEIC when the connected output supports it, otherwise JPEG.
  ///
  /// The compression quality must be from `0.0` to `1.0`.
  case automatic(quality: Double = 0.9)
}
