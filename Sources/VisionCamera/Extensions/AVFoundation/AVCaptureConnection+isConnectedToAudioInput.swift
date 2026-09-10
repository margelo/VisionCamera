///
/// AVCaptureConnection+isConnectedToAudioInput.swift
/// VisionCamera
/// Copyright © 2025 Marc Rousavy @ Margelo
///

import AVFoundation
import Foundation

extension AVCaptureConnection {
  var isConnectedToAudioInput: Bool {
    return inputPorts.allSatisfy { port in port.input.isMicrophone }
  }
}
