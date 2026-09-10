///
/// VisionCamera.swift
/// VisionCamera
/// Copyright © 2025 Marc Rousavy @ Margelo
///

import AVFoundation
import Foundation

public final class VisionCamera {
  private let queue = DispatchQueue(label: "com.margelo.camera.factory", qos: .userInitiated)

  public init() {}
  public var cameraPermissionStatus: PermissionStatus {
    let status = AVCaptureDevice.authorizationStatus(for: .video)
    return PermissionStatus(avStatus: status)
  }

  public var microphonePermissionStatus: PermissionStatus {
    let status = AVCaptureDevice.authorizationStatus(for: .audio)
    return PermissionStatus(avStatus: status)
  }

  public func requestCameraPermission() async throws -> Bool {
    try Bundle.main.requireCameraUsageDescription()
    return await AVCaptureDevice.requestAccess(for: .video)
  }

  public func requestMicrophonePermission() async throws -> Bool {
    try Bundle.main.requireMicrophoneUsageDescription()
    return await AVCaptureDevice.requestAccess(for: .audio)
  }

  public var supportsMultiCamSessions: Bool {
    return AVCaptureMultiCamSession.isMultiCamSupported
  }

  public func createCameraSession(enableMultiCam: Bool = false) throws -> CameraSession {
    guard !enableMultiCam || supportsMultiCamSessions else {
      throw CameraError(message: "This device does not support multi-camera sessions.")
    }
    return CameraSession(enableMultiCam: enableMultiCam)
  }

  public func createDeviceFactory() -> CameraDeviceFactory {
    return CameraDeviceFactory()
  }

  public func createPhotoOutput(options: PhotoOutputOptions = .init()) throws -> CameraPhotoOutput {
    return try CameraPhotoOutput(options: options)
  }

  public func createVideoOutput(options: VideoOutputOptions = .init()) -> any CameraVideoOutput {
    if options.enablePersistentRecorder == true {
      // On iOS, the `AVCaptureMovieFileOutput` does not allow flipping the Camera while
      // recording, which is a feature we call "enablePersistentRecorder".
      // So if the user plans on using persistent recordings, we need to create a custom
      // video output that uses `AVCaptureVideoDataOutput` + `AVAssetWriter` instead.
      return CameraVideoFrameOutput(options: options)
    } else {
      return MovieFileCameraVideoOutput(options: options)
    }
  }

  public func createFrameOutput(options: FrameOutputOptions = .init()) -> CameraFrameOutput {
    return CameraFrameOutput(options: options)
  }

  public func createDepthFrameOutput(options: DepthFrameOutputOptions = .init())
    -> CameraDepthFrameOutput
  {
    return CameraDepthFrameOutput(options: options)
  }

  public func createObjectOutput(options: ObjectOutputOptions) -> CameraObjectOutput {
    return CameraObjectOutput(options: options)
  }

  @MainActor
  public func createPreviewOutput() -> CameraPreviewOutput {
    return CameraPreviewOutput()
  }

  public func createOutputSynchronizer(outputs: [any CameraOutput]) throws
    -> CameraOutputSynchronizer
  {
    return try CameraOutputSynchronizer(outputs: outputs)
  }

  @MainActor
  public func createZoomGestureController() -> ZoomGestureController {
    return ZoomGestureController()
  }

  @MainActor
  public func createTapToFocusGestureController() -> TapToFocusGestureController {
    return TapToFocusGestureController()
  }

  public func createOrientationManager(orientationSource: OrientationSource)
    -> any OrientationManager
  {
    switch orientationSource {
    case .interface:
      return InterfaceOrientationManager()
    case .device:
      return DeviceOrientationManager()
    }
  }

  public func createFrameRenderer() -> FrameRenderer {
    return FrameRenderer()
  }

  public func createNormalizedMeteringPoint(x: Double, y: Double, size: Double? = nil)
    -> MeteringPoint
  {
    return MeteringPoint(normalizedX: x, normalizedY: y, normalizedSize: size ?? 0.1)
  }

  public func resolveConstraints(
    device: CameraDevice,
    outputConfigurations: [CameraOutputConfiguration],
    constraints: [Constraint],
    requiresMultiCam: Bool? = nil
  ) async throws -> CameraSessionConfig {
    return try await queue.perform {
      let outputs = outputConfigurations.map { $0.output }
      let resolvedConstraints = try ConstraintResolver.resolveConstraints(
        for: device,
        constraints: constraints,
        outputs: outputs,
        isMultiCam: requiresMultiCam == true)
      return CameraSessionConfig(
        negotiatedFormat: resolvedConstraints.negotiatedFormat,
        enabledConstraints: resolvedConstraints.enabledConstraints)
    }
  }
}
