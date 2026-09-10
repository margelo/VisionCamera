// Copyright © 2025 Marc Rousavy @ Margelo

/// Represents a ``PhotoContainerFormat`` that
/// can be used to capture Photos in.
public enum TargetPhotoContainerFormat: CaseIterable, Sendable {
  /// Captures a processed JPEG photo.
  case jpeg
  /// Captures a processed HEIC photo.
  case heic
  /// Captures a RAW photo in a Digital Negative container.
  case dng
  /// Uses HEIC, the default processed photo format for this capture pipeline.
  case native

}
