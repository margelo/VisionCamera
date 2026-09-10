///
/// AVCaptureConnection+isConnectedTo.swift
/// VisionCamera
/// Copyright © 2025 Marc Rousavy @ Margelo
///

import AVFoundation
import Foundation

extension AVCaptureConnection {
  func isConnectedTo(output: any CameraOutput) -> Bool {
    switch output {
    case let cameraOutput as any NativeCameraOutput:
      // compare AVCaptureOutput
      return self.output == cameraOutput.output
    case let previewOutput as any NativePreviewViewOutput:
      // compare AVCapturePreviewLayer
      return self.videoPreviewLayer == previewOutput.previewLayer
    default:
      // wrong type
      return false
    }
  }

  func isConnectedTo(output: ResolvedCameraSessionConnection.Output) -> Bool {
    switch output {
    case .output(let output):
      return self.output == output.output
    case .preview(let preview):
      return self.videoPreviewLayer == preview.previewLayer
    }
  }
}
