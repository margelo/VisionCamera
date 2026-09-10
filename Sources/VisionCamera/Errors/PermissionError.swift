// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation
import Foundation

/// A missing usage description or authorization required to use a Camera or microphone.
public enum PermissionError: Error, LocalizedError {
  /// The app's Info.plist does not contain the required privacy usage description.
  case missingUsageDescription(key: String)
  /// Camera capture requires authorization that the app does not currently have.
  case cameraAccessDenied(status: AVAuthorizationStatus)
  /// Audio capture requires authorization that the app does not currently have.
  case microphoneAccessDenied(status: AVAuthorizationStatus)

  /// A description of the missing permission or app configuration.
  public var errorDescription: String? {
    switch self {
    case .missingUsageDescription(let key):
      return "Add \(key) to Info.plist before requesting access."
    case .cameraAccessDenied(let status):
      return "Camera access is not authorized. Current permission status: \(status)."
    case .microphoneAccessDenied(let status):
      return "Microphone access is not authorized. Current permission status: \(status)."
    }
  }
}
