// Copyright © 2025 Marc Rousavy @ Margelo

/// Represents the container format of a captured Photo.
public enum PhotoContainerFormat: CaseIterable, Sendable {
  /// The captured Photo uses an unknown container format.
  case unknown
  /// The JPEG container format for compressed photos.
  case jpeg
  /// The High Efficiency Image Container format.
  case heic
  /// The Digital Negative container format for RAW photos.
  case dng
  /// The Tagged Image File Format.
  case tiff
  /// The DICOM medical image container format.
  case dcm

}
