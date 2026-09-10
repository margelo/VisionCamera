// Copyright © 2025 Marc Rousavy @ Margelo

/// Configures flash for photo capture.
///
/// See ``CameraPhotoOutput/capturePhoto(settings:callbacks:)``
public enum FlashMode: CaseIterable, Sendable {
  /// Always fires the flash when capturing the Photo, when supported by the device.
  case on
  /// Does not fire the flash when capturing the Photo.
  case off
  /// Lets the capture pipeline decide whether the scene needs flash.
  case auto

}
