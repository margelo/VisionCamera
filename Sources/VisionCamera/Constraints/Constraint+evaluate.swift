import AVFoundation

extension Constraint {
  func evaluate(for format: AVCaptureDevice.Format) throws(CameraError) -> ConstraintEvaluation {
    switch self {
    case .fps(let fpsConstraint):
      let r = fpsConstraint.resolve(for: format)
      return ConstraintEvaluation(penalty: r.penalty, resolved: .fps(r.resolvedValue))
    case .videoStabilizationMode(let videoStab):
      let r = videoStab.resolve(for: format)
      return ConstraintEvaluation(penalty: r.penalty, resolved: .videoStabilizationMode(r.resolvedValue))
    case .previewStabilizationMode(let previewStab):
      let r = previewStab.resolve(for: format)
      return ConstraintEvaluation(penalty: r.penalty, resolved: .previewStabilizationMode(r.resolvedValue))
    case .resolutionBias(let resolutionBias):
      let r = try resolutionBias.resolve(for: format)
      return ConstraintEvaluation(penalty: r.penalty, resolved: .formatOnly)
    case .videoDynamicRange(let dynamicRange):
      let r = dynamicRange.resolve(for: format)
      return ConstraintEvaluation(penalty: r.penalty, resolved: .videoDynamicRange(r.resolvedValue))
    case .photoHDR(_):
      // Photo HDR is not supported on iOS.
      return ConstraintEvaluation(penalty: .noPenalty, resolved: .formatOnly)
    case .pixelFormat(let pixelFormat):
      let r = pixelFormat.resolve(for: format)
      return ConstraintEvaluation(penalty: r.penalty, resolved: .formatOnly)
    case .binned(let binned):
      let r = binned.resolve(for: format)
      return ConstraintEvaluation(penalty: r.penalty, resolved: .formatOnly)
    }
  }
}
