// Copyright © 2026 Marc Rousavy @ Margelo

import AVFoundation
import Foundation

@MainActor
final class CameraCoordinator {
  let session: CameraSession
  let configureSession: ([CameraSessionConnection], CameraSessionConfiguration) async throws -> [CameraController]
  let output = PreviewOutput()
  let scheduler = CameraUpdateScheduler()
  weak var preview: PreviewView?
  var camera: Camera?
  var revision = 0
  var controller: CameraController?
  var attemptedConfiguration: CameraViewConfiguration?
  var configuredConfiguration: CameraViewConfiguration?
  var needsConfiguredEvent = false
  var didNotifyPreview = false
  var previewCleanup: ((PreviewView?) -> Void)?
  var reportedZoomConflict = false
  var subscriptions: [ObservationToken] = []
  var subjectSubscription: CameraQueuedSubscription?
  var zoomSubscription: ObservationToken?
  var zoomGesture: ZoomGestureController?
  var focusGesture: TapToFocusGestureController?
  var appliedControllerConfiguration: CameraControllerConfiguration?
  var appliedZoom: Double?
  var appliedExposure: Double?
  var appliedTorch: AVCaptureDevice.TorchMode?
  var requestedRunning = false
  var deviceOrientationManager: DeviceOrientationManager?
  var orientationGeneration = 0
  var deviceOrientation: CameraOrientation?
  var interfaceOrientation: CameraOrientation?
  var appliedOutputOrientation: CameraOrientation?
  var lastUIRotation: Double?

  init(
    session: CameraSession = CameraSession(),
    configureSession: (([CameraSessionConnection], CameraSessionConfiguration) async throws -> [CameraController])? = nil
  ) {
    self.session = session
    self.configureSession = configureSession ?? { try await session.configure($0, configuration: $1) }
  }

  func mount(camera: Camera, preview: PreviewView) {
    self.preview = preview
    self.camera = camera
    subscriptions = [
      session.observeStarted { [weak self] in self?.camera?.callbacks.onStarted?() },
      session.observeStopped { [weak self] in self?.camera?.callbacks.onStopped?() },
      session.observeErrors { [weak self] error in self?.report(error) },
      session.observeInterruptionStarted { [weak self] reason in self?.camera?.callbacks.onInterruptionStarted?(reason) },
      session.observeInterruptionEnded { [weak self] in self?.camera?.callbacks.onInterruptionEnded?() },
    ]
    preview.didStartPreview = { [weak self] in self?.camera?.callbacks.onPreviewStarted?() }
    preview.didStopPreview = { [weak self] in self?.camera?.callbacks.onPreviewStopped?() }
    preview.onInterfaceOrientationChanged = { [weak self] orientation in
      guard let self, self.camera != nil else { return }
      self.interfaceOrientation = orientation
      self.scheduleUpdate()
    }
    preview.output = output
    interfaceOrientation = preview.interfaceOrientation
    update(camera: camera)
  }

  func update(camera: Camera) {
    if camera.options.isActive && self.camera?.options.isActive == false && controller == nil {
      // Allow an explicit inactive-to-active transition to retry a failed configuration.
      attemptedConfiguration = nil
    }
    self.camera = camera
    revision += 1
    if preview?.resizeMode != camera.options.resizeMode { preview?.resizeMode = camera.options.resizeMode }
    updateGestures()
    updateSubjectSubscription()
    scheduleUpdate()
  }

  func dismantle() {
    guard camera != nil else { return }
    let onPreviewChanged = previewCleanup
    previewCleanup = nil
    self.camera = nil
    revision += 1
    for subscription in subscriptions { subscription.cancel() }
    subscriptions.removeAll()
    subjectSubscription?.cancel()
    subjectSubscription = nil
    zoomSubscription?.cancel()
    zoomSubscription = nil
    stopDeviceOrientationTracking()
    orientationGeneration += 1
    preview?.didStartPreview = nil
    preview?.didStopPreview = nil
    preview?.onInterfaceOrientationChanged = nil
    preview?.gestureControllers = []
    preview?.output = nil
    zoomGesture = nil
    focusGesture = nil
    preview = nil
    // SwiftUI may dismantle during a view update. Deliver state changes after that transaction.
    scheduler.schedule {
      onPreviewChanged?(nil)
      await self.reconcile()
    }
  }

  func scheduleUpdate() {
    scheduler.schedule { await self.reconcile() }
  }

  func report(_ error: any Error) {
    guard let camera else { return }
    if let onError = camera.callbacks.onError {
      onError(error)
    } else {
      logger.error("Camera encountered an error: \(error)")
    }
  }

  func replaceController(_ controller: CameraController?) {
    subjectSubscription?.cancel()
    subjectSubscription = nil
    self.controller = controller
    appliedControllerConfiguration = nil
    appliedZoom = nil
    appliedExposure = nil
    appliedTorch = nil
    zoomGesture?.controller = controller
    focusGesture?.controller = controller
    updateSubjectSubscription()
  }
}
