// Copyright © 2025 Marc Rousavy @ Margelo

/// Represents the physical position of a ``CameraDevice`` on the device.
/// - ``CameraPosition/front``: The Camera is located on the front of the device, typically used for selfies.
/// - ``CameraPosition/back``: The Camera is located on the back of the device, typically used for capturing the scene.
/// - ``CameraPosition/external``: The Camera is an external Camera (e.g. USB, Continuity Camera).
/// - ``CameraPosition/unspecified``: The Camera's position is unknown or not applicable.
public enum CameraPosition: CaseIterable, Sendable {
  /// The Camera is an external Camera (e.g. USB, Continuity Camera).
  case external
  /// The Camera is located on the front of the device, typically used for selfies.
  case front
  /// The Camera is located on the back of the device, typically used for capturing the scene.
  case back
  /// The Camera's position is unknown or not applicable.
  case unspecified

}
