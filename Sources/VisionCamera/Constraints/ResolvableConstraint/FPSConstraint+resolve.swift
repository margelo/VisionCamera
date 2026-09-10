// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation

extension FPSConstraint: ResolvableConstraint {
  typealias ResolvedValue = Double

  func resolve(for format: AVCaptureDevice.Format) throws(ConfigurationError) -> ConstraintResolution<Double> {
    return try resolve(frameRateRanges: format.videoSupportedFrameRateRanges.map { $0.minFrameRate...$0.maxFrameRate })
  }

  func resolve(frameRateRanges: [ClosedRange<Double>]) throws(ConfigurationError) -> ConstraintResolution<Double> {
    guard fps.isFinite, fps > 0 else {
      throw ConfigurationError.invalidFrameRate
    }
    let candidates = frameRateRanges.map { range in
      let selectedFPS = min(max(fps, range.lowerBound), range.upperBound)
      return ConstraintResolution(penalty: ConstraintPenalty(distance: abs(selectedFPS - fps)), resolvedValue: selectedFPS)
    }
    guard let nearest = candidates.min(by: { $0.penalty.distance < $1.penalty.distance }) else {
      throw ConfigurationError.frameRateRangesUnavailable
    }
    return nearest
  }

  func frameDuration(minimum: CMTime, maximum: CMTime) throws(ConfigurationError) -> CMTime {
    guard fps.isFinite, fps > 0 else {
      throw ConfigurationError.invalidFrameRate
    }
    let duration = CMTime(seconds: 1 / fps, preferredTimescale: 1_000_000_000)
    // Clamp rounding at native frame-duration boundaries before assigning AVFoundation properties.
    return min(max(duration, minimum), maximum)
  }
}
