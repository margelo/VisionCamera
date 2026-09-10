// Copyright © 2026 Marc Rousavy @ Margelo

import Foundation

extension CameraCoordinator {
  func reconcile() async {
    guard let camera else {
      await stop()
      replaceController(nil)
      do {
        _ = try await configureSession([], nil)
      } catch {
        logger.error("Failed to disconnect Camera: \(error)")
      }
      return
    }
    let options = camera.options
    let revision = self.revision
    if !didNotifyPreview, let action = camera.callbacks.onPreviewChanged, let preview {
      didNotifyPreview = true
      previewCleanup = action
      action(preview)
    }
    let hasZoomConflict = options.enableZoomGesture && options.zoom?.isFixed == true
    if hasZoomConflict && !reportedZoomConflict {
      report(CameraError(message: "A fixed zoom cannot be combined with the native zoom gesture. Pass a zoom binding or disable the gesture."))
    }
    reportedZoomConflict = hasZoomConflict
    if hasZoomConflict {
      stopDeviceOrientationTracking()
      if requestedRunning { await stop() }
      return
    }
    updateOrientationTracking()

    if !options.isActive && requestedRunning { await stop() }
    guard self.camera?.options.configuration == options.configuration else { return }

    if attemptedConfiguration != options.configuration {
      // A configured device can keep its torch on while inputs change.
      if controller != nil, appliedTorch != .off { await turnTorchOff() }
      guard self.camera?.options.configuration == options.configuration else { return }
      replaceController(nil)
      configuredConfiguration = nil
      attemptedConfiguration = options.configuration
      appliedOutputOrientation = nil
      var connection = options.configuration.connection(
        preview: previewOutput,
        initialZoom: options.zoom?.value ?? options.initialZoom,
        initialExposureBias: options.exposureBias ?? options.initialExposureBias)
      connection.onSessionConfigSelected = { [weak self] config in
        DispatchQueue.main.async {
          guard let self, self.camera?.options.configuration == options.configuration else { return }
          self.camera?.callbacks.onSessionConfigSelected?(config)
        }
      }
      do {
        let controllers = try await configureSession([connection], options.configuration.sessionConfiguration)
        guard self.camera?.options.configuration == options.configuration else { return }
        guard let controller = controllers.first else {
          throw CameraError(message: "Camera configuration did not return a controller.")
        }
        replaceController(controller)
        configuredConfiguration = options.configuration
        needsConfiguredEvent = true
      } catch {
        if self.camera?.options.configuration == options.configuration { report(error) }
        await stop()
        return
      }
    }

    guard self.camera?.options.configuration == configuredConfiguration, let controller else { return }
    await updateControls(options: options, controller: controller)
    await updateOutputOrientation()
    guard self.camera != nil, self.revision == revision else { return }
    if needsConfiguredEvent {
      needsConfiguredEvent = false
      self.camera?.callbacks.onConfigured?(controller)
    }
    guard self.camera != nil, self.revision == revision else { return }
    if options.isActive {
      if !requestedRunning {
        requestedRunning = true
        await session.start()
      }
      // Starting AVFoundation can suspend while a newer SwiftUI update deactivates the Camera.
      guard self.camera?.options.isActive == true, self.revision == revision else { return }
      if appliedTorch != options.torchMode {
        appliedTorch = options.torchMode
        do { try await controller.setTorchMode(mode: options.torchMode) } catch { report(error) }
      }
    }
  }

  func updateControls(options: CameraViewOptions, controller: CameraController) async {
    let revision = self.revision
    if appliedControllerConfiguration != options.controllerConfiguration {
      appliedControllerConfiguration = options.controllerConfiguration
      if options.controllerConfiguration != CameraControllerConfiguration() {
        do { try await controller.configure(config: options.controllerConfiguration) } catch { report(error) }
      }
    }
    guard self.controller === controller, camera != nil, self.revision == revision else { return }
    if let zoom = options.zoom?.value, zoom != appliedZoom,
      !(options.enableZoomGesture && options.zoom?.isFixed == true)
    {
      appliedZoom = zoom
      do { try await controller.setZoom(zoom: zoom) } catch { report(error) }
    }
    guard self.controller === controller, camera != nil, self.revision == revision else { return }
    if let exposure = options.exposureBias, exposure != appliedExposure {
      appliedExposure = exposure
      do { try await controller.setExposureBias(exposure: exposure) } catch { report(error) }
    }
  }

  func turnTorchOff() async {
    guard let controller, appliedTorch != .off else { return }
    appliedTorch = .off
    do { try await controller.setTorchMode(mode: .off) } catch { report(error) }
  }

  func stop() async {
    await turnTorchOff()
    requestedRunning = false
    await session.stop()
  }
}
