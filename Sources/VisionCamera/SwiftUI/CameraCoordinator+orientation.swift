// Copyright © 2026 Marc Rousavy @ Margelo

import Foundation

extension CameraCoordinator {
  func updateOrientationTracking() {
    guard let camera else { return }
    let tracksDevice = camera.options.orientationSource == .device && camera.options.isActive
    if tracksDevice && deviceOrientationManager == nil {
      let manager = DeviceOrientationManager()
      deviceOrientationManager = manager
      orientationGeneration += 1
      let generation = orientationGeneration
      do {
        try manager.startUpdates { [weak self] orientation in
          DispatchQueue.main.async {
            guard let self, self.camera != nil, self.orientationGeneration == generation else { return }
            self.deviceOrientation = orientation
            self.scheduleUpdate()
          }
        }
      } catch {
        // Retain the manager until tracking is disabled, so ordinary body updates do not repeat errors.
        report(error)
      }
    } else if !tracksDevice && deviceOrientationManager != nil {
      stopDeviceOrientationTracking()
    }
    if camera.options.orientationSource == nil {
      appliedOutputOrientation = nil
      lastUIRotation = nil
    }
  }

  func stopDeviceOrientationTracking() {
    guard let deviceOrientationManager else { return }
    deviceOrientationManager.stopUpdates()
    self.deviceOrientationManager = nil
    orientationGeneration += 1
  }

  func updateOutputOrientation() async {
    guard let camera else { return }
    let revision = self.revision
    let generation = orientationGeneration
    let orientation: CameraOrientation?
    switch camera.options.orientationSource {
    case .device: orientation = deviceOrientation
    case .interface: orientation = interfaceOrientation
    case nil: return
    }
    guard let orientation else { return }
    if appliedOutputOrientation != orientation {
      appliedOutputOrientation = orientation
      await session.setOutputOrientation(orientation, outputs: camera.options.configuration.outputs)
    }
    guard self.camera != nil, self.revision == revision, orientationGeneration == generation,
      (camera.options.orientationSource == .device ? deviceOrientation : interfaceOrientation) == orientation,
      let interfaceOrientation
    else { return }
    let rotation = Self.uiRotation(output: orientation, interface: interfaceOrientation)
    guard let onUIRotationChanged = self.camera?.callbacks.onUIRotationChanged else {
      lastUIRotation = nil
      return
    }
    if lastUIRotation != rotation {
      lastUIRotation = rotation
      onUIRotationChanged(rotation)
    }
  }

  static func uiRotation(output: CameraOrientation, interface: CameraOrientation) -> Double {
    let degrees = (interface.degrees - output.degrees + 360) % 360
    return Double(degrees > 180 ? degrees - 360 : degrees)
  }
}
