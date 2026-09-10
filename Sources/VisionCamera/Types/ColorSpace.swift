// Copyright © 2025 Marc Rousavy @ Margelo

/// Represents the color space of a captured video stream.
public enum ColorSpace: CaseIterable, Sendable {
  /// The color space is unknown.
  case unknown
  /// The standard sRGB color space.
  case srgb
  /// The Dolby Vision color space. This iOS pipeline negotiates an HLG fallback for this target.
  case dolbyVision
  /// The Display P3 color space with a D65 white point.
  case p3D65
  /// The HLG transfer function with the BT.2020 color space for HDR video.
  case hlgBt2020
  /// The Apple Log color space for workflows that apply color grading after capture.
  case appleLog
  /// The Apple Log 2 color space for supported Cameras and capture formats.
  case appleLog2

}
