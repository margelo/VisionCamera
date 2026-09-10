// Copyright © 2026 Marc Rousavy @ Margelo

import SwiftUI

/// A SwiftUI Camera that manages a capture session and displays its preview.
///
/// The Camera keeps its session and preview alive for its mounted view identity. Changing its
/// device, outputs, constraints, mirroring, or session configuration reconfigures that same session.
/// Control values and callbacks update independently. Removing the view stops and disconnects it.
///
/// Request Camera permission before mounting this view. Your app decides when capture is active,
/// for example by combining navigation visibility with SwiftUI's `scenePhase`.
/// Keep outputs in a stable owner, such as a `@StateObject`, instead of creating them in `body`.
///
/// ```swift
/// Camera(device: .position(.back), isActive: scenePhase == .active)
///   .enableZoomGesture()
///   .enableTapToFocusGesture()
///   .onError { error in print(error) }
/// ```
@MainActor
public struct Camera: View {
  var options: CameraViewOptions
  var callbacks = CameraCallbacks()

  /// Creates a Camera using a specific device or the default device at a position.
  ///
  /// - Parameters:
  ///   - device: The input Camera or a position for automatic device selection.
  ///   - isActive: Whether the configured session should run. An inactive Camera stays configured.
  ///   - outputs: Stable output instances, in resolution priority order. The Camera adds its own preview first.
  ///   - constraints: Ordered format preferences. Explicit constraints take priority over the automatic
  ///     resolution preferences for the preview and each supplied output.
  public init(
    device: CameraDeviceOrPosition,
    isActive: Bool,
    outputs: [any CameraOutput] = [],
    constraints: [Constraint] = []
  ) {
    options = CameraViewOptions(
      configuration: CameraViewConfiguration(device: device, outputs: outputs, constraints: constraints),
      isActive: isActive)
  }

  /// Creates a Camera using a discovered device.
  ///
  /// Keep the supplied outputs alive across view updates. The Camera adds its own preview output.
  public init(
    device: CameraDevice,
    isActive: Bool,
    outputs: [any CameraOutput] = [],
    constraints: [Constraint] = []
  ) {
    self.init(device: .device(device), isActive: isActive, outputs: outputs, constraints: constraints)
  }

  /// The preview backed by this Camera's stable UIKit coordinator.
  public var body: some View {
    CameraRepresentable(camera: self)
  }
}
