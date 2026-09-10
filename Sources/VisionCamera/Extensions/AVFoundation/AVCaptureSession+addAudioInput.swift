///
/// AVCaptureSession+addAudioInput.swift
/// VisionCamera
/// Copyright © 2025 Marc Rousavy @ Margelo
///

import AVFoundation
import Foundation

extension AVCaptureSession {
  func addAudioInput() throws {
    guard let microphone = AVCaptureDevice.default(for: .audio) else {
      throw ConfigurationError.microphoneUnavailable
    }
    let input = try AVCaptureDeviceInput(device: microphone)
    guard canAddInput(input) else {
      throw ConfigurationError.inputRejected(deviceID: microphone.uniqueID)
    }
    logger.info("Adding microphone \(input)...")
    self.addInputWithNoConnections(input)
  }
  func addAudioConnection(to output: AVCaptureOutput) throws {
    guard let audioDevice = self.inputs.first(where: { $0.isMicrophone }) else {
      throw ConfigurationError.audioInputNotConnected
    }
    guard let audioPort = audioDevice.ports.first(where: { $0.mediaType == .audio }) else {
      throw ConfigurationError.audioPortUnavailable
    }
    let connection = AVCaptureConnection(
      inputPorts: [audioPort],
      output: output)
    guard self.canAddConnection(connection) else {
      throw ConfigurationError.connectionRejected(mediaType: .audio)
    }
    self.addConnection(connection)
  }
}
