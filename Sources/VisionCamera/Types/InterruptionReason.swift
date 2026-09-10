// Copyright © 2025 Marc Rousavy @ Margelo

public enum InterruptionReason: String, CaseIterable, Sendable {
  case unknown
  case videoDeviceNotAvailableInBackground = "video-device-not-available-in-background"
  case audioDeviceInUseByAnotherClient = "audio-device-in-use-by-another-client"
  case videoDeviceInUseByAnotherClient = "video-device-in-use-by-another-client"
  case videoDeviceNotAvailableWithMultipleForegroundApps = "video-device-not-available-with-multiple-foreground-apps"
  case videoDeviceNotAvailableDueToSystemPressure = "video-device-not-available-due-to-system-pressure"
  case sensitiveContentMitigationActivated = "sensitive-content-mitigation-activated"

  public var stringValue: String {
    rawValue
  }

  public init?(fromString string: String) {
    self.init(rawValue: string)
  }
}
