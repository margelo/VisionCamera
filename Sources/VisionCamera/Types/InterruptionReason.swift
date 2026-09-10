// Copyright © 2025 Marc Rousavy @ Margelo

/// Describes why a Camera session was interrupted.
///
/// The session reports this value through its interruption-started listener.
public enum InterruptionReason: CaseIterable, Sendable {
  /// The Camera session was interrupted for an unknown reason.
  case unknown
  /// The Camera is unavailable because the app moved to the background.
  case videoDeviceNotAvailableInBackground
  /// Another client is using the audio device.
  case audioDeviceInUseByAnotherClient
  /// Another client is using the Camera device.
  case videoDeviceInUseByAnotherClient
  /// The Camera is unavailable while multiple apps are in the foreground.
  case videoDeviceNotAvailableWithMultipleForegroundApps
  /// The Camera is unavailable because of system pressure.
  case videoDeviceNotAvailableDueToSystemPressure
  /// The system interrupted capture to mitigate sensitive content.
  case sensitiveContentMitigationActivated

}
