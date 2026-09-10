///
/// NegotiatedFormat.swift
/// VisionCamera
/// Copyright © 2025 Marc Rousavy @ Margelo
///

import AVFoundation

public struct NegotiatedFormat {
  public let format: AVCaptureDevice.Format
  public let depthFormat: AVCaptureDevice.Format?

  public init(format: AVCaptureDevice.Format, depthFormat: AVCaptureDevice.Format?) {
    self.format = format
    self.depthFormat = depthFormat
  }
}
