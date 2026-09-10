// Copyright © 2025 Marc Rousavy @ Margelo

/// A camera configuration preference. Earlier constraints have higher priority.
public enum Constraint {
  case fps(FPSConstraint)
  case videoStabilizationMode(VideoStabilizationModeConstraint)
  case previewStabilizationMode(PreviewStabilizationModeConstraint)
  case resolutionBias(ResolutionBiasConstraint)
  case videoDynamicRange(VideoDynamicRangeConstraint)
  case photoHDR(PhotoHDRConstraint)
  case pixelFormat(PixelFormatConstraint)
  case binned(BinnedConstraint)
}
