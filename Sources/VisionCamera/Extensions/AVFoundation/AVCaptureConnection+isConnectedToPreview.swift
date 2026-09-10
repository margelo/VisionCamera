///
/// AVCaptureConnection+isConnectedToPreview.swift
/// VisionCamera
/// Copyright © 2025 Marc Rousavy @ Margelo
///

import AVFoundation
import Foundation

extension AVCaptureConnection {
  var isConnectedToPreview: Bool {
    return videoPreviewLayer != nil
  }
}
