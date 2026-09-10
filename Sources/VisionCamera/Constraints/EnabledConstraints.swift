///
/// EnabledConstraints.swift
/// VisionCamera
/// Copyright © 2025 Marc Rousavy @ Margelo
///

import AVFoundation
import Foundation

/// The values selected for constraints that change a camera connection's capture behavior.
///
/// A `nil` value means that negotiation did not select a specific value for that constraint.
public struct EnabledConstraints {
  /// The selected frame rate, in frames per second.
  public let selectedFPS: Double?
  /// The selected stabilization mode for video streams.
  public let selectedVideoStabilizationMode: TargetStabilizationMode?
  /// The selected stabilization mode for preview streams.
  public let selectedPreviewStabilizationMode: TargetStabilizationMode?
  /// The selected dynamic range for video streams.
  public let selectedVideoDynamicRange: DynamicRange?

  /// Creates a set of selected constraint values.
  ///
  /// - Parameters:
  ///   - selectedFPS: The frame rate, or `nil` if no specific rate was selected.
  ///   - selectedVideoStabilizationMode: The video stabilization mode, or `nil` if none was selected.
  ///   - selectedPreviewStabilizationMode: The preview stabilization mode, or `nil` if none was selected.
  ///   - selectedVideoDynamicRange: The video dynamic range, or `nil` if none was selected.
  public init(
    selectedFPS: Double?, selectedVideoStabilizationMode: TargetStabilizationMode?, selectedPreviewStabilizationMode: TargetStabilizationMode?,
    selectedVideoDynamicRange: DynamicRange?
  ) {
    self.selectedFPS = selectedFPS
    self.selectedVideoStabilizationMode = selectedVideoStabilizationMode
    self.selectedPreviewStabilizationMode = selectedPreviewStabilizationMode
    self.selectedVideoDynamicRange = selectedVideoDynamicRange
  }
}
