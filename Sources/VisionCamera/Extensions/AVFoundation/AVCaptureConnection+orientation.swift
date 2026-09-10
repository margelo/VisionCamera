///
/// AVCaptureConnection+orientation.swift
/// VisionCamera
/// Copyright © 2025 Marc Rousavy @ Margelo
///

import AVFoundation
import Foundation

extension AVCaptureConnection {
  var orientation: CameraOrientation {
    return CameraOrientation(avOrientation: videoOrientation)
  }

  func setOrientation(_ orientation: CameraOrientation) throws {
    guard self.isVideoOrientationSupported else {
      throw CameraError(
        message:
          "Cannot set orientation=\"\(orientation)\" - this connection does not support orientation changing"
      )
    }
    self.videoOrientation = orientation.toAVCaptureVideoOrientation()
  }
}
