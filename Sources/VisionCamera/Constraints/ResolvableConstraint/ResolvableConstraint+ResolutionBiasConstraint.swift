///
/// ResolvableConstraint+ResolutionBiasConstraint.swift
/// VisionCamera
/// Copyright © 2025 Marc Rousavy @ Margelo
///

import AVFoundation

extension ResolutionBiasConstraint: ResolvableConstraint {
  typealias ResolvedValue = Void

  func resolve(for format: AVCaptureDevice.Format) throws(ConfigurationError) -> ConstraintResolution<Void> {
    let output = self.resolutionBias
    guard let resolutionNegotiationsParticipant = output as? any ResolutionNegotiationParticipant else {
      throw ConfigurationError.resolutionNegotiationUnsupported(outputType: String(describing: type(of: output)))
    }

    let streamType = resolutionNegotiationsParticipant.streamType
    let supportedResolutions = format.supportedResolutions(for: streamType)
    let penalty: Double
    switch resolutionNegotiationsParticipant.targetResolution {
    case .closest(let targetResolution):
      let targetResolution = targetResolution.toCMVideoDimensions()
      guard let closestSupportedResolution = supportedResolutions.nearest(to: targetResolution) else {
        throw ConfigurationError.resolutionsUnavailable(streamType: streamType)
      }
      penalty = closestSupportedResolution.penalty(targetResolution)
    case .atLeast(let minimumResolution):
      let minimumResolution = minimumResolution.toCMVideoDimensions()
      guard let smallestPenalty = supportedResolutions.map({ $0.penalty(coveringAtLeast: minimumResolution) }).min() else {
        throw ConfigurationError.resolutionsUnavailable(streamType: streamType)
      }
      penalty = smallestPenalty
    case .any:
      penalty = 0.0
    }

    return ConstraintResolution(
      penalty: ConstraintPenalty(distance: penalty),
      resolvedValue: ())
  }
}
