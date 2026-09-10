///
/// NativePreviewViewOutput.swift
/// VisionCamera
/// Copyright © 2025 Marc Rousavy @ Margelo
///

import AVFoundation
import Foundation

/// The native extension point for Camera previews backed by `AVCaptureVideoPreviewLayer` and participating in resolution negotiation.
public protocol NativePreviewViewOutput: AnyObject, ResolutionNegotiationParticipant {
  /// The preview layer connected to the Camera input by ``CameraSession``.
  var previewLayer: AVCaptureVideoPreviewLayer { get }

  /// Called whenever the output configuration might change, in a `beginConfiguration()`/`commitConfiguration()` batch.
  ///
  /// The preview output is expected to apply orientation and mirroring settings here. ``CameraSession`` calls this method on its serial configuration queue.
  /// - Throws: If the preview cannot apply an explicitly requested setting.
  func configure(_ config: OutputConfiguration) throws
}
