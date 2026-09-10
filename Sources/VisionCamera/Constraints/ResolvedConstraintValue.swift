import AVFoundation

enum ResolvedConstraintValue {
  case fps(Double)
  case videoStabilizationMode(TargetStabilizationMode)
  case previewStabilizationMode(TargetStabilizationMode)
  case videoDynamicRange(DynamicRange)
  /// Constraint only affects format selection, not enabled settings
  case formatOnly
}
