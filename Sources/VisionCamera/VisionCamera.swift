///
/// VisionCamera.swift
/// VisionCamera
/// Copyright © 2025 Marc Rousavy @ Margelo
///

import AVFoundation
import Foundation

/// Discover Cameras, request permissions, and query Camera capabilities.
///
/// Use ``VisionCamera`` directly without creating an instance. Create sessions,
/// outputs, and other Camera objects using their initializers.
///
/// ```swift
/// if try await VisionCamera.requestCameraPermission(),
///    let device = VisionCamera.defaultCamera(for: .back) {
///   let session = CameraSession()
///   let photoOutput = PhotoOutput()
///   let controllers = try await session.configure([
///     CameraSessionConnection(
///       input: .device(device),
///       outputs: [CameraOutputConfiguration(output: photoOutput)]
///     )
///   ])
///   await session.start()
/// }
/// ```
public enum VisionCamera {
  private static let queue = DispatchQueue(label: "com.margelo.camera.constraints", qos: .userInitiated)

  /// Get the current Camera ``PermissionStatus``.
  public static var cameraPermissionStatus: PermissionStatus {
    let status = AVCaptureDevice.authorizationStatus(for: .video)
    return PermissionStatus(avStatus: status)
  }

  /// Get the current Microphone ``PermissionStatus``.
  public static var microphonePermissionStatus: PermissionStatus {
    let status = AVCaptureDevice.authorizationStatus(for: .audio)
    return PermissionStatus(avStatus: status)
  }

  /// Request Camera permission.
  /// - Returns: `true` if Camera permission has now been granted, `false` otherwise.
  ///
  /// - Throws: If `NSCameraUsageDescription` is missing from the app's Info.plist.
  public static func requestCameraPermission() async throws(PermissionError) -> Bool {
    try Bundle.main.requireCameraUsageDescription()
    return await AVCaptureDevice.requestAccess(for: .video)
  }

  /// Request Microphone permission.
  /// - Returns: `true` if Microphone permission has now been granted, `false` otherwise.
  ///
  /// - Throws: If `NSMicrophoneUsageDescription` is missing from the app's Info.plist.
  public static func requestMicrophonePermission() async throws(PermissionError) -> Bool {
    try Bundle.main.requireMicrophoneUsageDescription()
    return await AVCaptureDevice.requestAccess(for: .audio)
  }

  /// Gets whether the platform supports creating multi-cam
  /// ``CameraSession``s.
  ///
  /// Older phones may not be able to support this.
  /// See ``CameraSession/init(isMultiCamEnabled:)``
  public static var supportsMultiCamSessions: Bool {
    return AVCaptureMultiCamSession.isMultiCamSupported
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
  /// The ``Constraint/resolution(_:)`` ``Constraint`` is optional, but
  /// may rank the given ``CameraOutput``'s resolution above other
  /// ``Constraint``s.
  /// To give output resolutions the lowest priority, append a
  /// ``Constraint/resolution(_:)`` for each output after your explicit constraints.
  /// Resolution biases are not added automatically.
  ///
  /// ```swift
  /// let config = try await VisionCamera.resolve(
  ///   [
  ///     .frameRate(30),
  ///     .resolution(photoOutput)
  ///   ],
  ///   for: device,
  ///   outputs: [CameraOutputConfiguration(output: photoOutput)]
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
  public static func resolve(
    _ constraints: [Constraint],
    for device: CameraDevice,
    outputs outputConfigurations: [CameraOutputConfiguration],
    requiresMultiCam: Bool = false
  ) async throws -> CameraSessionConfig {
    return try await queue.perform {
      let outputs = outputConfigurations.map { $0.output }
      let resolvedConstraints = try ConstraintResolver.resolveConstraints(
        for: device,
        constraints: constraints,
        outputs: outputs,
        isMultiCam: requiresMultiCam)
      return CameraSessionConfig(
        negotiatedFormat: resolvedConstraints.negotiatedFormat,
        enabledConstraints: resolvedConstraints.enabledConstraints)
    }
  }
}
