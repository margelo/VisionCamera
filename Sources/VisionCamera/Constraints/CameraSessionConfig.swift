///
/// CameraSessionConfig.swift
/// VisionCamera
/// Copyright © 2025 Marc Rousavy @ Margelo
///

import AVFoundation
import Foundation

public final class CameraSessionConfig {
  public let negotiatedFormat: NegotiatedFormat
  public let enabledConstraints: EnabledConstraints

  init(negotiatedFormat: NegotiatedFormat, enabledConstraints: EnabledConstraints) {
    self.negotiatedFormat = negotiatedFormat
    self.enabledConstraints = enabledConstraints
  }

  public var selectedFPS: Double? {
    return enabledConstraints.selectedFPS
  }

  public var selectedVideoStabilizationMode: TargetStabilizationMode? {
    return enabledConstraints.selectedVideoStabilizationMode
  }

  public var selectedPreviewStabilizationMode: TargetStabilizationMode? {
    return enabledConstraints.selectedPreviewStabilizationMode
  }

  public var selectedVideoDynamicRange: TargetDynamicRange? {
    return enabledConstraints.selectedVideoDynamicRange
  }

  public var isPhotoHDREnabled: Bool {
    // Highest Photo Quality implies Smart HDR, this is not directly controllable.
    return negotiatedFormat.format.isHighestPhotoQualitySupported
  }

  public var nativePixelFormat: PixelFormat {
    let format = negotiatedFormat.format
    return PixelFormat(mediaSubType: format.formatDescription.mediaSubType)
  }

  public var autoFocusSystem: AutoFocusSystem {
    let format = negotiatedFormat.format
    return AutoFocusSystem(af: format.autoFocusSystem)
  }

  public var isBinned: Bool {
    return negotiatedFormat.format.isVideoBinned
  }

  public func toString() -> String {
    let components = [
      "format: \(negotiatedFormat.format)",
      "selectedFPS: \(String(describing: selectedFPS))",
      "selectedVideoStabilizationMode: \(String(describing: selectedVideoStabilizationMode))",
      "selectedPreviewStabilizationMode: \(String(describing: selectedPreviewStabilizationMode))",
      "selectedVideoDynamicRange: \(String(describing: selectedVideoDynamicRange))",
      "isPhotoHDREnabled: \(isPhotoHDREnabled)",
    ]
    return "CameraSessionConfig(\(components.joined(separator: ", ")))"
  }
}
