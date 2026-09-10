///
/// VisionCamera.swift
/// VisionCamera
/// Copyright © 2025 Marc Rousavy @ Margelo
///

import AVFoundation
import Foundation

/// The ``VisionCamera`` allows creating various other
/// Camera related objects with arguments.
public final class VisionCamera {
  private let queue = DispatchQueue(label: "com.margelo.camera.factory", qos: .userInitiated)

  /// Creates a factory for Camera sessions, devices, outputs, and utilities.
  public init() {}
  /// Get the current Camera ``PermissionStatus``.
  public var cameraPermissionStatus: PermissionStatus {
    let status = AVCaptureDevice.authorizationStatus(for: .video)
    return PermissionStatus(avStatus: status)
  }

  /// Get the current Microphone ``PermissionStatus``.
  public var microphonePermissionStatus: PermissionStatus {
    let status = AVCaptureDevice.authorizationStatus(for: .audio)
    return PermissionStatus(avStatus: status)
  }

  /// Request Camera permission.
  /// - Returns: `true` if Camera permission has now been granted, `false` otherwise.
  ///
  /// - Throws: If `NSCameraUsageDescription` is missing from the app's Info.plist.
  public func requestCameraPermission() async throws -> Bool {
    try Bundle.main.requireCameraUsageDescription()
    return await AVCaptureDevice.requestAccess(for: .video)
  }

  /// Request Microphone permission.
  /// - Returns: `true` if Microphone permission has now been granted, `false` otherwise.
  ///
  /// - Throws: If `NSMicrophoneUsageDescription` is missing from the app's Info.plist.
  public func requestMicrophonePermission() async throws -> Bool {
    try Bundle.main.requireMicrophoneUsageDescription()
    return await AVCaptureDevice.requestAccess(for: .audio)
  }

  /// Gets whether the platform supports creating multi-cam
  /// ``CameraSession``s.
  ///
  /// Older phones may not be able to support this.
  /// See ``VisionCamera/createCameraSession(enableMultiCam:)``
  public var supportsMultiCamSessions: Bool {
    return AVCaptureMultiCamSession.isMultiCamSupported
  }

  /// Creates a new ``CameraSession``.
  ///
  /// - If `enableMultiCam` is `true`, the ``CameraSession``
  /// supports attaching multiple ``CameraDevice``s as inputs/connections
  /// at the same time.
  /// - If `enableMultiCam` is `false`, the ``CameraSession``
  /// only supports a single ``CameraDevice`` input at a time.
  ///
  /// - Throws: If `enableMultiCam` is `true`, but ``VisionCamera/supportsMultiCamSessions`` is `false`.
  public func createCameraSession(enableMultiCam: Bool = false) throws -> CameraSession {
    guard !enableMultiCam || supportsMultiCamSessions else {
      throw CameraError(message: "This device does not support multi-camera sessions.")
    }
    return CameraSession(enableMultiCam: enableMultiCam)
  }

  /// Create a new ``CameraDeviceFactory``.
  public func createDeviceFactory() -> CameraDeviceFactory {
    return CameraDeviceFactory()
  }

  /// Create a new ``CameraPhotoOutput``
  /// with the given ``PhotoOutputOptions``.
  public func createPhotoOutput(options: PhotoOutputOptions = .init()) -> CameraPhotoOutput {
    return CameraPhotoOutput(options: options)
  }

  /// Create a new ``CameraVideoOutput``
  /// with the given ``VideoOutputOptions``.
  ///
  /// Returns a ``CameraVideoFrameOutput`` when ``VideoOutputOptions/enablePersistentRecorder`` is enabled, or a ``MovieFileCameraVideoOutput`` otherwise.
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

  /// Create a new ``CameraFrameOutput``
  /// with the given ``FrameOutputOptions``.
  public func createFrameOutput(options: FrameOutputOptions = .init()) -> CameraFrameOutput {
    return CameraFrameOutput(options: options)
  }

  /// Create a new ``CameraDepthFrameOutput``
  /// with the given ``DepthFrameOutputOptions``.
  public func createDepthFrameOutput(options: DepthFrameOutputOptions = .init())
    -> CameraDepthFrameOutput
  {
    return CameraDepthFrameOutput(options: options)
  }

  /// Create a new ``CameraObjectOutput``
  /// with the given ``ObjectOutputOptions``.
  public func createObjectOutput(options: ObjectOutputOptions) -> CameraObjectOutput {
    return CameraObjectOutput(options: options)
  }

  /// Create a new ``CameraPreviewOutput``.
  @MainActor
  public func createPreviewOutput() -> CameraPreviewOutput {
    return CameraPreviewOutput()
  }

  /// Create a new ``CameraOutputSynchronizer`` that
  /// synchronizes the given `outputs`.
  ///
  /// - Throws: If fewer than two outputs are given, an output does not conform to ``NativeCameraOutput``, or an output is not connected to a session.
  public func createOutputSynchronizer(outputs: [any CameraOutput]) throws
    -> CameraOutputSynchronizer
  {
    return try CameraOutputSynchronizer(outputs: outputs)
  }

  /// Creates a new ``ZoomGestureController``.
  @MainActor
  public func createZoomGestureController() -> ZoomGestureController {
    return ZoomGestureController()
  }

  /// Creates a new ``TapToFocusGestureController``.
  @MainActor
  public func createTapToFocusGestureController() -> TapToFocusGestureController {
    return TapToFocusGestureController()
  }

  /// Creates a new ``OrientationManager``.
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

  /// Create a new ``FrameRenderer``.
  public func createFrameRenderer() -> FrameRenderer {
    return FrameRenderer()
  }

  /// Creates a normalized ``MeteringPoint``, where `x` and `y` are
  /// values in the normalized range from 0.0 to 1.0.
  ///
  /// Your are responsible for handling orientation, cropping and scaling.
  /// - Parameter x: The X coordinate ranging from 0.0 to 1.0
  /// - Parameter y: The Y coordinate ranging from 0.0 to 1.0
  /// - Parameter size: The size/radius of the ``MeteringPoint``
  public func createNormalizedMeteringPoint(x: Double, y: Double, size: Double? = nil)
    -> MeteringPoint
  {
    return MeteringPoint(normalizedX: x, normalizedY: y, normalizedSize: size ?? 0.1)
  }

  /// Resolves the given `constraints` to a fully validated
  /// ``CameraSessionConfig`` respecting the given `device`'s
  /// capabilities negotiated with the given `outputConfigurations`.
  ///
  /// The given `constraints` are ranked by priority in their
  /// order passed in the array, descending.
  /// The first item (index `0`) has highest priority, while the last item
  /// has lowest priority.
  ///
  /// On a device that supports every possible combination of features,
  /// the returned ``CameraSessionConfig`` features exactly what was
  /// described in the given `constraints`.
  /// Most devices however negotiate available features across the given
  /// `outputConfigurations` because of bandwidth constraints or
  /// simply feature compatibility - for example, 10-bit Video HDR is often
  /// not supported when used in conjunction with 100+ FPS.
  /// Also, maximum available video resolution is often only available when
  /// using a lower photo resolution, and vice-versa.
  ///
  /// The ``ResolutionBiasConstraint`` ``Constraint`` is optional, but
  /// may rank the given ``CameraOutput``'s resolution above other
  /// ``Constraint``s.
  /// To give output resolutions the lowest priority, append a
  /// ``ResolutionBiasConstraint`` for each output after your explicit constraints.
  /// Resolution biases are not added automatically.
  ///
  /// ```swift
  /// let config = try await camera.resolveConstraints(
  ///   device: device,
  ///   outputConfigurations: [CameraOutputConfiguration(output: photoOutput)],
  ///   constraints: [
  ///     .fps(FPSConstraint(fps: 30)),
  ///     .resolutionBias(ResolutionBiasConstraint(resolutionBias: photoOutput))
  ///   ]
  /// )
  /// ```
  ///
  /// - Parameters:
  ///   - device: The camera whose supported formats should be negotiated.
  ///   - outputConfigurations: The outputs that the camera will stream to.
  ///   - constraints: Your preferences in priority order, with the most important first.
  ///   - requiresMultiCam: Whether the selected format must support simultaneous camera capture. Defaults to `false`.
  /// - Returns: The selected native formats and resolved constraint values, without configuring or starting a session.
  /// - Throws: An error if no format supports the outputs or a constraint cannot be evaluated, or `CancellationError` if canceled before resolution begins.
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
