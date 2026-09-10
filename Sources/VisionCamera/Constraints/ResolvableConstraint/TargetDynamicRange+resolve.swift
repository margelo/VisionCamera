// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation

extension TargetDynamicRange {
  func resolve(for format: AVCaptureDevice.Format) throws(CameraError) -> ConstraintResolution<DynamicRange> {
    return try resolve(
      mediaSubType: format.formatDescription.mediaSubType,
      supportedColorSpaces: format.supportedColorSpaces)
  }

  func resolve(
    mediaSubType: CMFormatDescription.MediaSubType,
    supportedColorSpaces: [AVCaptureColorSpace]
  ) throws(CameraError) -> ConstraintResolution<DynamicRange> {
    let actualBitDepth = mediaSubType.bitDepth
    let bitDepthPenalty = self.bitDepth.penalty(to: actualBitDepth)
    let colorSpaceResolution = try self.colorSpace.resolve(supportedColorSpaces: supportedColorSpaces)
    let actualColorRange = mediaSubType.colorRange
    let colorRangePenalty = self.colorRange.toColorRange().penalty(to: actualColorRange)
    let totalPenalty = Double(bitDepthPenalty + colorRangePenalty) + colorSpaceResolution.penalty.distance

    return ConstraintResolution(
      penalty: ConstraintPenalty(distance: totalPenalty),
      resolvedValue: DynamicRange(
        bitDepth: actualBitDepth,
        colorSpace: colorSpaceResolution.resolvedValue,
        colorRange: actualColorRange))
  }
}
