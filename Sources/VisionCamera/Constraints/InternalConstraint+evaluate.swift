import AVFoundation

extension InternalConstraint {
  func evaluate(for format: AVCaptureDevice.Format) throws(CameraError) -> ConstraintEvaluation {
    switch self {
    case .userConstraint(let constraint):
      return try constraint.evaluate(for: format)
    case .preferredAutoFocusSystem(let afSystem):
      let r = afSystem.resolve(for: format)
      return ConstraintEvaluation(penalty: r.penalty, resolved: .formatOnly)
    case .preferHighestPhotoQuality:
      let penalty = format.isHighestPhotoQualitySupported ? 0.0 : 1.0
      return ConstraintEvaluation(
        penalty: ConstraintPenalty(distance: penalty),
        resolved: .formatOnly)
    case .preferHighQualityPrioritization:
      let penalty = format.isHighPhotoQualitySupported ? 0.0 : 1.0
      return ConstraintEvaluation(
        penalty: ConstraintPenalty(distance: penalty),
        resolved: .formatOnly)
    }
  }
}
