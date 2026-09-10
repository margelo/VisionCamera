// Copyright © 2025 Marc Rousavy @ Margelo

public enum InterruptionReason: CaseIterable, Sendable {
  case unknown
  case videoDeviceNotAvailableInBackground
  case audioDeviceInUseByAnotherClient
  case videoDeviceInUseByAnotherClient
  case videoDeviceNotAvailableWithMultipleForegroundApps
  case videoDeviceNotAvailableDueToSystemPressure
  case sensitiveContentMitigationActivated
}
