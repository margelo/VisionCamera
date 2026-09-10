import AVFoundation

extension Constraint {
  func evaluate(for format: AVCaptureDevice.Format) throws(ConfigurationError) -> ConstraintEvaluation {
    switch self {
    case .frameRate(let frameRate):
      let r = try FPSConstraint(fps: frameRate).resolve(for: format)
      return ConstraintEvaluation(penalty: r.penalty, resolved: .fps(r.resolvedValue))
    case .videoStabilization(let videoStab):
      let r = VideoStabilizationModeConstraint(videoStabilizationMode: videoStab).resolve(for: format)
      return ConstraintEvaluation(penalty: r.penalty, resolved: .videoStabilizationMode(r.resolvedValue))
    case .previewStabilization(let previewStab):
      let r = PreviewStabilizationModeConstraint(previewStabilizationMode: previewStab).resolve(for: format)
      return ConstraintEvaluation(penalty: r.penalty, resolved: .previewStabilizationMode(r.resolvedValue))
    case .resolution(let resolutionBias):
      let r = try ResolutionBiasConstraint(resolutionBias: resolutionBias).resolve(for: format)
      return ConstraintEvaluation(penalty: r.penalty, resolved: .formatOnly)
    case .videoDynamicRange(let dynamicRange):
      let r = try VideoDynamicRangeConstraint(videoDynamicRange: dynamicRange).resolve(for: format)
      return ConstraintEvaluation(penalty: r.penalty, resolved: .videoDynamicRange(r.resolvedValue))
    case .pixelFormat(let pixelFormat):
      let r = PixelFormatConstraint(pixelFormat: pixelFormat).resolve(for: format)
      return ConstraintEvaluation(penalty: r.penalty, resolved: .formatOnly)
    case .binned(let binned):
      let r = BinnedConstraint(binned: binned).resolve(for: format)
      return ConstraintEvaluation(penalty: r.penalty, resolved: .formatOnly)
    }
  }
}
