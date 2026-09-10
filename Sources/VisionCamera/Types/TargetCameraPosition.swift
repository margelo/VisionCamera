// Copyright © 2025 Marc Rousavy @ Margelo

/// Represents the target physical position of a ``CameraDevice`` on the device.
/// - ``TargetCameraPosition/front``: Target Cameras located on the front of the device, typically used for selfies.
/// - ``TargetCameraPosition/back``: Target Cameras located on the back of the device, typically used for capturing the scene.
/// - ``TargetCameraPosition/external``: Target external Cameras (e.g. USB, Continuity Camera).
public enum TargetCameraPosition: CaseIterable, Sendable {
  /// Target external Cameras (e.g. USB, Continuity Camera).
  case external
  /// Target Cameras located on the front of the device, typically used for selfies.
  case front
  /// Target Cameras located on the back of the device, typically used for capturing the scene.
  case back

}
