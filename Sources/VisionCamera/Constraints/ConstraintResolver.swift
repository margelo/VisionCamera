///
/// ConstraintResolver.swift
/// VisionCamera
/// Copyright © 2025 Marc Rousavy @ Margelo
///

import AVFoundation
import Foundation

// FrameOutput's exact output pixel format is validated after the output is connected. A
// PixelFormatConstraint separately expresses a preference for the camera's native capture format.

enum ConstraintResolver {
  static func resolveConstraints(
    for device: CameraDeviceOrPosition,
    constraints: [Constraint],
    outputs: [any CameraOutput],
    isMultiCam: Bool
  ) throws -> ResolvedConstraints {
    let device = try AVCaptureDevice.resolve(value: device)
    return try resolveConstraints(
      for: device,
      constraints: constraints,
      outputs: outputs,
      isMultiCam: isMultiCam)
  }

  static func resolveConstraints(
    for device: CameraDevice,
    constraints: [Constraint],
    outputs: [any CameraOutput],
    isMultiCam: Bool
  ) throws -> ResolvedConstraints {
    return try resolveConstraints(
      for: device.device,
      constraints: constraints,
      outputs: outputs,
      isMultiCam: isMultiCam)
  }

  static func resolveConstraints(
    for device: AVCaptureDevice,
    constraints: [Constraint],
    outputs: [any CameraOutput],
    isMultiCam: Bool
  ) throws -> ResolvedConstraints {
    let outputs = try outputs.compactMap { output in
      switch output {
      case let output as any NativeCameraOutput:
        return output
      case is any NativePreviewViewOutput:
        return nil
      default:
        throw CameraError(
          message:
            "Connection output \"\(output)\" is not of type `NativeCameraOutput` or `NativePreviewViewOutput`!"
        )
      }
    }
    return try resolveConstraints(
      for: device,
      constraints: constraints,
      outputs: outputs,
      isMultiCam: isMultiCam)
  }

  static func resolveConstraints(
    for device: AVCaptureDevice,
    constraints userConstraints: [Constraint],
    outputs: [any NativeCameraOutput],
    isMultiCam: Bool
  ) throws -> ResolvedConstraints {
    // Build the full constraint list: user constraints first (highest priority),
    // then inferred internal constraints (lowest priority).
    var constraints: [InternalConstraint] = userConstraints.map { .userConstraint($0) }
    constraints.append(.preferredAutoFocusSystem(.phaseDetection))
    if outputs.contains(where: { $0.streamType == .photo }) {
      constraints.append(.preferHighQualityPrioritization)
      constraints.append(.preferHighestPhotoQuality)
    }

    // Hard requirements: filter out formats that are not possible at all.
    let formats = try filterFormats(device.formats, outputs: outputs, isMultiCam: isMultiCam)

    // Evaluate all formats and pick the one with the lowest total penalty.
    // This is a single pass - format selection and enabled constraints
    // are computed together from the same resolve() calls.
    guard
      let best =
        try formats
        .map({ try evaluate($0, constraints: constraints) })
        .min(by: { $0.totalPenalty < $1.totalPenalty })
    else {
      throw CameraError(message: "The given `device` does not have any `formats`!")
    }
    logger.debug("Selected Format: \(best.format)")

    // If we need depth data, also find the best depth format
    let needsDepth = outputs.contains { $0.requiresDepthFormat }
    // TODO: Don't just choose the first format, but also negotiate depth data format in our constraint resolution.
    let bestDepthFormat = needsDepth ? best.format.supportedDepthDataFormats.first : nil

    return ResolvedConstraints(
      device: device,
      negotiatedFormat: NegotiatedFormat(format: best.format, depthFormat: bestDepthFormat),
      enabledConstraints: best.enabledConstraints)
  }

  // MARK: - Format Evaluation

  /// Evaluates all constraints against a single format in one pass.
  /// Returns the format, its total weighted penalty, and the enabled constraints
  /// that would apply if this format is selected.
  private static func evaluate(
    _ format: AVCaptureDevice.Format,
    constraints: [InternalConstraint]
  ) throws(CameraError) -> FormatEvaluation {
    var totalPenalty = 0.0

    // First-match-wins accumulators (priority order = array order)
    var fps: Double?
    var videoStabilizationMode: TargetStabilizationMode?
    var previewStabilizationMode: TargetStabilizationMode?
    var videoDynamicRange: DynamicRange?

    for (index, constraint) in constraints.enumerated() {
      let weight = Double(constraints.count - index)
      let evaluation = try constraint.evaluate(for: format)
      totalPenalty += evaluation.penalty.distance * weight

      // Accumulate enabled values - first of each type wins (= highest priority)
      switch evaluation.resolved {
      case .fps(let value):
        if fps == nil { fps = value }
      case .videoStabilizationMode(let value):
        if videoStabilizationMode == nil { videoStabilizationMode = value }
      case .previewStabilizationMode(let value):
        if previewStabilizationMode == nil { previewStabilizationMode = value }
      case .videoDynamicRange(let value):
        if videoDynamicRange == nil { videoDynamicRange = value }
      case .formatOnly:
        break
      }
    }

    let enabledConstraints = EnabledConstraints(
      selectedFPS: fps,
      selectedVideoStabilizationMode: videoStabilizationMode,
      selectedPreviewStabilizationMode: previewStabilizationMode,
      selectedVideoDynamicRange: videoDynamicRange)

    return FormatEvaluation(
      format: format,
      totalPenalty: totalPenalty,
      enabledConstraints: enabledConstraints)
  }

  // MARK: - Hard Filters

  /// Filters out formats that we cannot support at all.
  /// These are hard requirements, not soft constraints/biases.
  private static func filterFormats(
    _ formats: [AVCaptureDevice.Format],
    outputs: [any NativeCameraOutput],
    isMultiCam: Bool
  ) throws(CameraError) -> [AVCaptureDevice.Format] {
    var formats = formats
    guard !formats.isEmpty else {
      throw CameraError(message: "The given `device` does not have any `formats`!")
    }

    // 1. If we need a Depth Output, filter out formats without depth support
    let needsDepth = outputs.contains { $0.requiresDepthFormat }
    if needsDepth {
      formats = formats.filter { !$0.supportedDepthDataFormats.isEmpty }
      guard !formats.isEmpty else {
        throw CameraError(
          message:
            "The given `device` does not have any `formats` that have `supportedDepthDataFormats`. Does this device support depth?"
        )
      }
    }

    // 2. If multi-cam, ensure formats support it
    if isMultiCam {
      formats = formats.filter { $0.isMultiCamSupported }
      guard !formats.isEmpty else {
        throw CameraError(
          message:
            "The given `device` does not have any `formats` that support multi-cam sessions! Does this `device` support multi-cam?"
        )
      }
    }

    // 3. Ensure formats support all target outputs
    formats = formats.filter { format in
      outputs.allSatisfy { format.supportsOutput($0.output) }
    }
    guard !formats.isEmpty else {
      throw CameraError(
        message:
          "The given `device` does not have any `formats` that support the attached Outputs!")
    }

    return formats
  }
}
