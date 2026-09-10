///
/// EnabledConstraints.swift
/// VisionCamera
/// Copyright © 2025 Marc Rousavy @ Margelo
///

import AVFoundation
import Foundation

public struct EnabledConstraints {
  public let selectedFPS: Double?
  public let selectedVideoStabilizationMode: TargetStabilizationMode?
  public let selectedPreviewStabilizationMode: TargetStabilizationMode?
  public let selectedVideoDynamicRange: TargetDynamicRange?

  public init(
    selectedFPS: Double?, selectedVideoStabilizationMode: TargetStabilizationMode?, selectedPreviewStabilizationMode: TargetStabilizationMode?,
    selectedVideoDynamicRange: TargetDynamicRange?
  ) {
    self.selectedFPS = selectedFPS
    self.selectedVideoStabilizationMode = selectedVideoStabilizationMode
    self.selectedPreviewStabilizationMode = selectedPreviewStabilizationMode
    self.selectedVideoDynamicRange = selectedVideoDynamicRange
  }
}
