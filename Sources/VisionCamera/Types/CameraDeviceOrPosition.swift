// Copyright © 2025 Marc Rousavy @ Margelo

/// Specifies the Camera device for a session connection.
///
/// Pass a device to choose a specific Camera, or a position to select the default Camera at that position.
public enum CameraDeviceOrPosition {
  /// Uses the given Camera device.
  case device(CameraDevice)
  /// Selects the default Camera at the given position.
  case position(TargetCameraPosition)
}
