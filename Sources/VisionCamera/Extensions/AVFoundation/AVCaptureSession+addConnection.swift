///
/// AVCaptureSession+addConnection.swift
/// VisionCamera
/// Copyright © 2025 Marc Rousavy @ Margelo
///

import AVFoundation
import Foundation

extension AVCaptureSession {
  func addConnection(input device: AVCaptureDevice, output: ResolvedCameraSessionConnection.Output) throws {
    // 1. Get the `AVCaptureDeviceInput` for our `device`
    let deviceInput = try findDevice(for: device)

    // 2. Create the `AVCaptureConnection` (either output or preview, we have an extension init)
    let connection = try AVCaptureConnection(input: deviceInput, output: output)

    // 3. Add it!
    guard self.canAddConnection(connection) else {
      throw CameraError(
        message: "Connection \"\(connection)\" cannot be added to Camera Session!")
    }
    logger.info("Adding Connection \(connection)...")
    self.addConnection(connection)
  }
}
