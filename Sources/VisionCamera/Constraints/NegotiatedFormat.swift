///
/// NegotiatedFormat.swift
/// VisionCamera
/// Copyright © 2025 Marc Rousavy @ Margelo
///

import AVFoundation

/// The native video and depth formats selected during constraint negotiation.
public struct NegotiatedFormat {
  /// The camera's selected video format.
  public let format: AVCaptureDevice.Format
  /// The selected depth format, or `nil` when no depth format is needed.
  public let depthFormat: AVCaptureDevice.Format?

  /// Creates a pair of native capture formats.
  ///
  /// - Parameters:
  ///   - format: The video format for the camera.
  ///   - depthFormat: A depth format supported by `format`, or `nil` for a connection without depth.
  public init(format: AVCaptureDevice.Format, depthFormat: AVCaptureDevice.Format?) {
    self.format = format
    self.depthFormat = depthFormat
  }
}
