///
/// AVCaptureSession+addOutputWithNoConnections.swift
/// VisionCamera
/// Copyright © 2025 Marc Rousavy @ Margelo
///

import AVFoundation
import Foundation

extension AVCaptureSession {
  func addOutputWithNoConnections(_ output: ResolvedCameraSessionConnection.Output) throws {
    switch output {
    case .output(let output):
      // It's a normal AVCaptureOutput
      let output = output.output
      guard output.connections.isEmpty else {
        throw ConfigurationError.outputAlreadyConnected(outputType: String(describing: type(of: output)))
      }
      guard canAddOutput(output) else {
        throw ConfigurationError.outputRejected(outputType: String(describing: type(of: output)))
      }
      logger.info("Adding Output \(output)...")
      addOutputWithNoConnections(output)

    case .preview(let preview):
      // It's an AVVideoPreviewLayer - we need to set its .session
      let previewLayer = preview.previewLayer
      guard previewLayer.session == nil else {
        throw ConfigurationError.outputAlreadyConnected(outputType: String(describing: type(of: preview)))
      }
      logger.info("Adding Preview \(previewLayer)...")
      previewLayer.setSessionWithNoConnection(self)
    }
  }
}
