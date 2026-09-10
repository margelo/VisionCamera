///
/// AVCaptureConnection+init.swift
/// VisionCamera
/// Copyright © 2025 Marc Rousavy @ Margelo
///

import AVFoundation
import Foundation

extension AVCaptureConnection {
  convenience init(input: AVCaptureDeviceInput, output: ResolvedCameraSessionConnection.Output) throws {
    let mediaType = output.mediaType.toAVMediaType()
    let targetPorts = input.ports.filter { $0.mediaType == mediaType }
    guard let firstPort = targetPorts.first else {
      throw ConfigurationError.inputPortUnavailable(deviceID: input.device.uniqueID, mediaType: output.mediaType.toAVMediaType())
    }

    switch output {
    case .output(let output):
      // a) It's a normal AVCaptureSessionOutput - connect it to all its desired ports
      self.init(inputPorts: targetPorts, output: output.output)
    case .preview(let preview):
      // b) It's a preview AVCapturePreviewLayer
      self.init(inputPort: firstPort, videoPreviewLayer: preview.previewLayer)
    }
  }
}
