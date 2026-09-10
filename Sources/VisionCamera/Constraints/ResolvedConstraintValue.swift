import AVFoundation

enum ResolvedConstraintValue {
  case fps(Double)
  case videoStabilizationMode(TargetStabilizationMode)
  case previewStabilizationMode(TargetStabilizationMode)
  case videoDynamicRange(TargetDynamicRange)
  /// Constraint only affects format selection, not enabled settings
  case formatOnly
}
