// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation

extension TargetColorSpace {
  func nextBestMode() -> TargetColorSpace? {
    switch self {
    case .srgb:
      return nil
    case .p3D65:
      return .srgb
    case .hlgBt2020:
      return .p3D65
    case .appleLog:
      return .hlgBt2020
    case .appleLog2:
      return .appleLog
    }
  }

  func resolve(supportedColorSpaces: [AVCaptureColorSpace]) throws(ConfigurationError) -> ConstraintResolution<ColorSpace> {
    var penalty = 0
    var candidate: TargetColorSpace? = self
    while let current = candidate {
      if let native = current.toAVCaptureColorSpace(), supportedColorSpaces.contains(native) {
        return ConstraintResolution(
          penalty: ConstraintPenalty(distance: Double(penalty)),
          resolvedValue: ColorSpace(colorSpace: native))
      }
      candidate = current.nextBestMode()
      penalty += 1
    }

    // Some external formats may omit sRGB. Use a reported, representable color space.
    for native in supportedColorSpaces {
      let colorSpace = ColorSpace(colorSpace: native)
      if colorSpace.toAVCaptureColorSpace() != nil {
        return ConstraintResolution(
          penalty: ConstraintPenalty(distance: Double(penalty)),
          resolvedValue: colorSpace)
      }
    }
    throw ConfigurationError.colorSpacesUnavailable
  }
}
