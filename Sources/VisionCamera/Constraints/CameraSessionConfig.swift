///
/// CameraSessionConfig.swift
/// VisionCamera
/// Copyright © 2025 Marc Rousavy @ Margelo
///

import AVFoundation
import Foundation

/// The session-level configuration selected for a camera connection.
///
/// A ``CameraSession`` negotiates this configuration from your ordered ``Constraint`` values
/// and connected outputs. You can also resolve a configuration before starting the session with
/// ``VisionCamera/resolveConstraints(device:outputConfigurations:constraints:requiresMultiCam:)``.
public final class CameraSessionConfig {
  /// The video format and optional depth format selected for the camera.
  public let negotiatedFormat: NegotiatedFormat
  /// The constraint values selected during format negotiation.
  public let enabledConstraints: EnabledConstraints

  init(negotiatedFormat: NegotiatedFormat, enabledConstraints: EnabledConstraints) {
    self.negotiatedFormat = negotiatedFormat
    self.enabledConstraints = enabledConstraints
  }

  /// Gets the currently selected FPS, or `nil` if no specific FPS value has been selected.
  public var selectedFPS: Double? {
    return enabledConstraints.selectedFPS
  }

  /// Gets the currently selected stabilization mode for video streams, or `nil` if no specific mode has been configured.
  ///
  /// This applies to outputs such as ``VideoOutput``.
  public var selectedVideoStabilizationMode: TargetStabilizationMode? {
    return enabledConstraints.selectedVideoStabilizationMode
  }

  /// Gets the currently selected stabilization mode for preview streams, or `nil` if no specific mode has been configured.
  ///
  /// This applies to ``PreviewOutput``.
  public var selectedPreviewStabilizationMode: TargetStabilizationMode? {
    return enabledConstraints.selectedPreviewStabilizationMode
  }

  /// Gets the currently selected dynamic range for video streams, or `nil` if no specific dynamic range has been configured.
  public var selectedVideoDynamicRange: DynamicRange? {
    return enabledConstraints.selectedVideoDynamicRange
  }

  /// Whether the selected capture format supports AVFoundation's highest photo quality.
  ///
  /// This capability does not describe whether HDR processing is active for a photo.
  public var supportsHighestPhotoQuality: Bool {
    return negotiatedFormat.format.isHighestPhotoQualitySupported
  }

  /// Gets the pixel format this configuration is natively streaming in.
  ///
  /// If this is the same ``PixelFormat`` as the requested pixel format of your streaming output, such as
  /// a ``FrameOutput``, no conversion has to take place to stream frames, which provides better performance and lower latency.
  ///
  /// If these pixel formats differ, pixel format conversions take place, causing higher latency which ultimately
  /// causes lower throughput and higher battery usage.
  public var nativePixelFormat: PixelFormat {
    let format = negotiatedFormat.format
    return PixelFormat(mediaSubType: format.formatDescription.mediaSubType)
  }

  /// Gets the autofocus system used by this configuration.
  public var autoFocusSystem: AutoFocusSystem {
    let format = negotiatedFormat.format
    return AutoFocusSystem(af: format.autoFocusSystem)
  }

  /// Gets whether this configuration is streaming in a binned format.
  ///
  /// Pixel binning combines multiple neighboring sensor pixels into one larger effective pixel.
  /// This usually improves low-light sensitivity and reduces noise, but can trade away fine detail
  /// compared to a full-resolution non-binned readout.
  /// Binned formats are also more performant as they use significantly less bandwidth.
  public var isBinned: Bool {
    return negotiatedFormat.format.isVideoBinned
  }

  /// Returns a description of the selected format and constraint values for debugging.
  ///
  /// - Returns: A readable description of this configuration.
  public func toString() -> String {
    let components = [
      "format: \(negotiatedFormat.format)",
      "selectedFPS: \(String(describing: selectedFPS))",
      "selectedVideoStabilizationMode: \(String(describing: selectedVideoStabilizationMode))",
      "selectedPreviewStabilizationMode: \(String(describing: selectedPreviewStabilizationMode))",
      "selectedVideoDynamicRange: \(String(describing: selectedVideoDynamicRange))",
      "supportsHighestPhotoQuality: \(supportsHighestPhotoQuality)",
    ]
    return "CameraSessionConfig(\(components.joined(separator: ", ")))"
  }
}
