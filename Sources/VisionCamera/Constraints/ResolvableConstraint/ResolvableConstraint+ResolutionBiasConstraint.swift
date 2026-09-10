///
/// ResolvableConstraint+ResolutionBiasConstraint.swift
/// VisionCamera
/// Copyright © 2025 Marc Rousavy @ Margelo
///

import AVFoundation

extension ResolutionBiasConstraint: ResolvableConstraint {
  typealias ResolvedValue = Void

  func resolve(for format: AVCaptureDevice.Format) throws(CameraError) -> ConstraintResolution<Void> {
    let output = self.resolutionBias
    guard let resolutionNegotiationsParticipant = output as? any ResolutionNegotiationParticipant else {
      throw CameraError(
        message:
          "The given CameraOutput (in `resolutionBias`) does not conform to `ResolutionNegotiationParticipant`!")
    }

    let streamType = resolutionNegotiationsParticipant.streamType
    let supportedResolutions = format.supportedResolutions(for: streamType)
    let penalty: Double
    switch resolutionNegotiationsParticipant.targetResolution {
    case .closestTo(let targetResolution):
      let targetResolution = targetResolution.toCMVideoDimensions()
      guard let closestSupportedResolution = supportedResolutions.nearest(to: targetResolution) else {
        throw CameraError(message: "Format \(format) does not have available resolutions for stream type \"\(streamType)\"!")
      }
      penalty = closestSupportedResolution.penalty(targetResolution)
    case .min(let minimumResolution):
      let minimumResolution = minimumResolution.toCMVideoDimensions()
      guard let smallestPenalty = supportedResolutions.map({ $0.penalty(coveringAtLeast: minimumResolution) }).min() else {
        throw CameraError(message: "Format \(format) does not have available resolutions for stream type \"\(streamType)\"!")
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
