// Copyright © 2025 Marc Rousavy @ Margelo

/// Specifies a target color space for video format negotiation.
///
/// Use this with ``TargetDynamicRange`` to request a color space supported by the Camera.
public enum TargetColorSpace: CaseIterable, Sendable {
  /// The standard sRGB color space.
  case srgb
  /// The Display P3 color space with a D65 white point.
  case p3D65
  /// The HLG transfer function with the BT.2020 color space for HDR video.
  case hlgBt2020
  /// The Apple Log color space for workflows that apply color grading after capture.
  case appleLog
  /// The Apple Log 2 color space for supported Cameras and capture formats.
  case appleLog2

}
