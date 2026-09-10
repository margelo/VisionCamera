///
/// AVCaptureSession+addInputWithNoConnections.swift
/// VisionCamera
/// Copyright © 2025 Marc Rousavy @ Margelo
///

import AVFoundation
import Foundation

extension AVCaptureSession {
  func addInputWithNoConnections(_ deviceOrPosition: CameraDeviceOrPosition) throws
    -> AVCaptureDeviceInput
  {
    let device = try AVCaptureDevice.resolve(value: deviceOrPosition)
    let deviceInput = try AVCaptureDeviceInput(device: device)
    guard canAddInput(deviceInput) else {
      throw ConfigurationError.inputRejected(deviceID: device.uniqueID)
    }
    logger.info("Adding input \(deviceInput)...")
    addInputWithNoConnections(deviceInput)
    return deviceInput
  }
}
