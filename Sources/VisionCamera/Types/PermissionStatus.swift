// Copyright © 2025 Marc Rousavy @ Margelo

/// Represents the status of a permission, such as Camera or Microphone access.
///
/// You can request permission when the status is ``PermissionStatus/notDetermined``.
public enum PermissionStatus: CaseIterable, Sendable {
  /// The app has not requested this permission yet.
  case notDetermined
  /// The app is authorized to use the service and can proceed.
  case authorized
  /// The user denied permission. Access can be enabled in Settings.
  case denied
  /// Access is restricted, for example by parental controls, and permission cannot be requested.
  case restricted

}
