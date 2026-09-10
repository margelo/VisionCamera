///
/// CameraDevice.swift
/// VisionCamera
/// Copyright © 2025 Marc Rousavy @ Margelo
///

import AVFoundation
import Foundation

/// The ``CameraDevice`` represents a physical- or
/// virtual Camera Device.
///
/// Examples:
/// - Physical: The 0.5x ultra-wide-angle Camera
/// - Virtual: The Triple-Camera consisting of the 0.5x, the 1x, and the 3x Camera
/// - TrueDepth Face ID: A virtual Camera consisting of a color, and a depth Camera
///
/// A Camera Device is a value that identifies a live AVFoundation device. Copies refer
/// to the same hardware and compare equal when their ``id`` values match.
/// Capabilities are read from the underlying device when accessed.
public struct CameraDevice: Identifiable, Hashable {
  /// The underlying AVFoundation capture device.
  public let device: AVCaptureDevice

  /// Creates a Camera device from an existing `AVCaptureDevice`.
  public init(device: AVCaptureDevice) {
    self.device = device
  }

  /// Get a list of all supported ``PixelFormat``s this
  /// ``CameraDevice`` can stream in.
  public var supportedPixelFormats: [PixelFormat] {
    let videoFormats = device.formats
    let depthFormats = device.formats.flatMap { $0.supportedDepthDataFormats }
    let allFormats = videoFormats + depthFormats
    return
      allFormats
      .map { PixelFormat(mediaSubType: $0.formatDescription.mediaSubType) }
      .withoutDuplicates()
  }

  /// Get a list of all supported resolutions this ``CameraDevice``
  /// can produce for outputs of the given ``StreamType``.
  ///
  /// If a given ``StreamType`` can not be streamed to at
  /// all, an empty array (`[]`) will be returned.
  ///
  /// While a ``CameraDevice`` may be able to stream in the
  /// given output resolutions individually, it is not guaranteed that
  /// all resolutions are available when streaming to multiple
  /// ``CameraOutput`` with multiple ``Constraint``s
  /// enabled.
  ///
  /// The ``CameraSession`` internally negotiates available
  /// output resolutions based on ``Constraint``s, and potentially
  /// downgrades (or upgrades) target resolutions if needed.
  ///
  /// See ``VideoOutputOptions/targetResolution``
  /// See ``PhotoOutputOptions/targetResolution``
  /// See ``FrameOutputOptions/targetResolution``
  /// See ``DepthOutputOptions/targetResolution``
  /// See ``Constraint/resolution(_:)``
  ///
  /// ```swift
  /// let resolutions = device.supportedResolutions(for: .photo)
  /// ```
  public func supportedResolutions(for streamType: StreamType) -> [CGSize] {
    return device.formats
      .flatMap { $0.supportedResolutions(for: streamType) }
      .withoutDuplicates()
      .map { CGSize(width: Int($0.width), height: Int($0.height)) }
  }

  /// Gets all available Frame Rate Ranges this
  /// ``CameraDevice`` supports individually.
  ///
  /// Frame Rates are expressed in FPS (Frames per Second),
  /// for example `60` refers to 60 FPS (= 16.666ms per Frame).
  ///
  /// Use ``CameraDevice/supports(frameRate:)`` as a convenience
  /// method to find out if a given fixed frame rate is supported
  /// individually.
  ///
  /// While a device may support a given FPS `ClosedRange<Double>`
  /// individually, it is not guaranteed to be supported with all
  /// possible feature and output combinations.
  ///
  /// The ``Constraint`` API (specifically ``Constraint/frameRate(_:)``)
  /// internally negotiates the target ``Constraint/frameRate(_:)``
  /// with other enabled features (such as ``Constraint/videoStabilization(_:)``)
  /// and all connected ``CameraOutput``s to find a best-matching
  /// supported combination on this device.
  ///
  /// Resolve the desired outputs and constraints with
  /// ``VisionCamera/resolve(_:for:outputs:requiresMultiCam:)``
  /// before starting a session. Connected-output support is checked when configuring the session.
  public var supportedFrameRateRanges: [ClosedRange<Double>] {
    return device.formats
      .flatMap { $0.videoSupportedFrameRateRanges }
      .withoutDuplicates()
      .map { $0.minFrameRate...$0.maxFrameRate }
  }

  /// Get a list of all ``DynamicRange``s this
  /// ``CameraDevice`` supports streaming at,
  /// often affecting both Video recordings and Preview.
  ///
  /// Unlike Photo HDR, Video Dynamic Ranges are not
  /// only extra processing, but often entirely different
  /// sensor readouts.
  /// While Photo HDR might capture multiple bracketed Photos
  /// to fuse them together to expose more colors, Video
  /// Dynamic Ranges sometimes stream in an entirely different
  /// Pixel Format (e.g. 10-bit instead of 8-bit), and use
  /// a different YUV Transfer Matrix to compose pixels from
  /// sensor data.
  ///
  /// While a device may support a given ``DynamicRange``
  /// individually, it is not guaranteed to be supported with all
  /// possible feature and output combinations.
  ///
  /// The ``Constraint`` API (specifically ``Constraint/videoDynamicRange(_:)``)
  /// internally negotiates the target Dynamic Range with
  /// other enabled features (such as ``Constraint/resolution(_:)`` or
  /// ``Constraint/frameRate(_:)``) and all connected ``CameraOutput``s
  /// to find a best-matching supported combination on this device.
  ///
  /// Resolve the desired outputs and constraints with
  /// ``VisionCamera/resolve(_:for:outputs:requiresMultiCam:)``
  /// before starting a session. Connected-output support is checked when configuring the session.
  ///
  /// See ``Constraint/videoDynamicRange(_:)``
  /// See ``VideoOutput``
  public var supportedVideoDynamicRanges: [DynamicRange] {
    return device.formats
      .flatMap { format in
        return format.supportedColorSpaces.map { colorSpace in
          return DynamicRange(
            bitDepth: format.bitDepth,
            colorSpace: ColorSpace(colorSpace: colorSpace),
            colorRange: format.colorRange)
        }
      }
      .withoutDuplicates()
  }

  /// Returns whether this ``CameraDevice``
  /// supports streaming to the given `output`.
  ///
  /// Usually, a ``CameraDevice`` can stream to all
  /// ``CameraOutput``s, with very rare exceptions.
  ///
  /// For example, Depth Frame Outputs (``DepthOutput``)
  /// may not be supported on all ``CameraDevice``s - see
  /// ``CameraDevice/mediaTypes``.
  public func supports(_ output: some CameraOutput) -> Bool {
    if output is any NativePreviewViewOutput {
      return device.hasMediaType(.video)
    }
    guard let output = output as? any NativeCameraOutput else {
      // Not a NativeCameraOutput!
      return false
    }
    return device.formats.contains { $0.supportsOutput(output.output) }
  }

  /// Gets whether the given `frameRate` is individually supported
  /// by any of the ``CameraDevice/supportedFrameRateRanges`` on this ``CameraDevice``.
  ///
  /// While a device may support a given FPS `ClosedRange<Double>`
  /// individually, it is not guaranteed to be supported with all
  /// possible feature and output combinations.
  ///
  /// The ``Constraint`` API (specifically ``Constraint/frameRate(_:)``)
  /// internally negotiates the target ``Constraint/frameRate(_:)``
  /// with other enabled features (such as ``Constraint/videoStabilization(_:)``)
  /// and all connected ``CameraOutput``s to find a best-matching
  /// supported combination on this device.
  ///
  /// Resolve the desired outputs and constraints with
  /// ``VisionCamera/resolve(_:for:outputs:requiresMultiCam:)``
  /// before starting a session. Connected-output support is checked when configuring the session.
  ///
  /// See ``CameraDevice/supportedFrameRateRanges``
  public func supports(frameRate: Double) -> Bool {
    return supportedFrameRateRanges.contains { range in
      range.contains(frameRate)
    }
  }

  /// Returns whether this ``CameraDevice`` supports
  /// the given `StabilizationMode` for video streams
  /// (e.g. ``VideoOutput``).
  ///
  /// While a device may support a given `StabilizationMode`
  /// individually, it is not guaranteed to be supported with all
  /// possible feature and output combinations.
  ///
  /// The ``Constraint`` API (specifically
  /// ``Constraint/videoStabilization(_:)``) internally
  /// negotiates the target ``Constraint/videoStabilization(_:)``
  /// with other enabled features (such as ``Constraint/frameRate(_:)``) and
  /// all connected ``CameraOutput``s to find a best-matching
  /// supported combination on this device.
  ///
  /// Resolve the desired outputs and constraints with
  /// ``VisionCamera/resolve(_:for:outputs:requiresMultiCam:)``
  /// before starting a session. Connected-output support is checked when configuring the session.
  public func supportsVideoStabilizationMode(videoStabilizationMode: TargetStabilizationMode) -> Bool {
    guard let stabilizationMode = videoStabilizationMode.toAVCaptureVideoStabilizationMode() else { return false }
    return device.formats.contains { $0.isVideoStabilizationModeSupported(stabilizationMode) }
  }

  /// Returns whether this ``CameraDevice`` supports
  /// the given `StabilizationMode` for preview streams
  /// (e.g. ``PreviewOutput``).
  ///
  /// While a device may support a given `StabilizationMode`
  /// individually, it is not guaranteed to be supported with all
  /// possible feature and output combinations.
  ///
  /// The ``Constraint`` API (specifically
  /// ``Constraint/previewStabilization(_:)``) internally
  /// negotiates the target ``Constraint/previewStabilization(_:)``
  /// with other enabled features (such as ``Constraint/frameRate(_:)``) and
  /// all connected ``CameraOutput``s to find a best-matching
  /// supported combination on this device.
  ///
  /// Resolve the desired outputs and constraints with
  /// ``VisionCamera/resolve(_:for:outputs:requiresMultiCam:)``
  /// before starting a session. Connected-output support is checked when configuring the session.
  public func supportsPreviewStabilizationMode(previewStabilizationMode: TargetStabilizationMode) -> Bool {
    // Each output has its own connection, but the active format defines the same supported modes.
    return supportsVideoStabilizationMode(videoStabilizationMode: previewStabilizationMode)
  }

  /// A unique identifier for this camera device.
  public var id: String {
    return device.uniqueID
  }

  /// The model identifier for this camera device.
  public var modelID: String {
    return device.modelID
  }

  /// A user friendly camera name shown by the system.
  public var localizedName: String {
    return device.localizedName
  }

  /// The hardware manufacturer name for this device.
  public var manufacturer: String {
    return device.manufacturer
  }

  /// The camera hardware type, for example
  /// ``DeviceType/wideAngle``.
  public var type: DeviceType {
    return DeviceType(type: device.deviceType)
  }

  /// The position of this camera on the device.
  public var position: CameraPosition {
    if #available(iOS 17.0, *) {
      // AVFoundation identifies external and Continuity Cameras by device type, not lens position.
      if device.deviceType == .external || device.deviceType == .continuityCamera {
        return .external
      }
    }
    return CameraPosition(position: device.position)
  }

  /// If this ``CameraDevice`` is a virtual
  /// device (see ``CameraDevice/isVirtualDevice``), this
  /// property contains a list of all constituent
  /// physical devices this virtual device is made of.
  ///
  /// For physical devices, this returns an empty array.
  public var physicalDevices: [CameraDevice] {
    device.constituentDevices.map { CameraDevice(device: $0) }
  }

  /// Gets whether this ``CameraDevice``
  /// is a virtual device, which consists of two or
  /// more physical ``CameraDevice``s.
  ///
  /// Devices like the "Triple-Camera" (0.5x + 1x + 3x)
  /// or the "FaceID Camera" (color + depth) are virtual
  /// devices.
  ///
  /// To access the individual physical devices
  /// a virtual device consists of, use ``CameraDevice/physicalDevices``.
  public var isVirtualDevice: Bool {
    return device.isVirtualDevice
  }

  /// The camera's nominal focal length in 35mm film format.
  @available(iOS 26.0, *)
  public var focalLength: Double {
    return Double(device.nominalFocalLengthIn35mmFilm)
  }

  /// The size (ƒ number) of the lens diaphragm.
  public var lensAperture: Double {
    return Double(device.lensAperture)
  }

  /// Whether this device is a Continuity Camera.
  @available(iOS 16.0, *)
  public var isContinuityCamera: Bool {
    return device.isContinuityCamera
  }

  /// The matching Desk View camera for this Continuity Camera, if available.
  @available(iOS 16.0, *)
  public var companionDeskViewCamera: CameraDevice? {
    guard let companion = device.companionDeskViewCamera else {
      return nil
    }
    return CameraDevice(device: companion)
  }

  /// Gets whether this ``CameraDevice``
  /// supports smoothly adjusting focus via
  /// ``CameraControllerConfiguration/isSmoothAutoFocusEnabled``.
  ///
  /// ```swift
  /// try await controller.configure(CameraControllerConfiguration(
  ///   isSmoothAutoFocusEnabled: device.supportsSmoothAutoFocus
  /// ))
  /// ```
  public var supportsSmoothAutoFocus: Bool {
    return device.isSmoothAutoFocusSupported
  }

  /// The minimum supported exposure compensation bias, in EV units.
  public var minExposureBias: Double {
    return Double(device.minExposureTargetBias)
  }
  /// The maximum supported exposure compensation bias, in EV units.
  public var maxExposureBias: Double {
    return Double(device.maxExposureTargetBias)
  }

  /// Whether this ``CameraDevice`` has a
  /// physical flash unit, or not.
  ///
  /// For ``CameraPosition/front``-facing
  /// devices, ``CameraDevice/hasFlash`` may be `false`,
  /// but you might still be able to use a screen-
  /// flash for photo capture.
  ///
  /// See ``CapturePhotoSettings/flashMode``
  public var hasFlash: Bool {
    return device.hasFlash
  }

  /// Whether the device has a torch for continuous illumination.
  ///
  /// Use ``CameraController/setTorchMode(_:)`` to select a native torch mode, or
  /// ``CameraController/setTorchModeOn(level:)`` to turn it on at a chosen brightness.
  public var hasTorch: Bool {
    return device.hasTorch
  }

  /// Whether this ``CameraDevice`` supports
  /// enabling low-light boost to improve exposure in
  /// dark scenes via ``CameraControllerConfiguration/isLowLightBoostEnabled``.
  ///
  /// ```swift
  /// try await controller.configure(CameraControllerConfiguration(
  ///   isLowLightBoostEnabled: device.supportsLowLightBoost
  /// ))
  /// ```
  public var supportsLowLightBoost: Bool {
    return device.isLowLightBoostSupported
  }

  /// The minimum individually supported zoom value of this device.
  ///
  /// - Note: Depending on the ``Constraint``s and
  /// ``CameraOutput``s configured on the
  /// ``CameraSession``, the actual minimum zoom
  /// value may change.
  /// Inspect the returned ``CameraController``'s
  /// ``CameraController/minZoom`` property
  /// for a true current minimum.
  public var minZoom: Double {
    return device.minAvailableVideoZoomFactor
  }

  /// The maximum individually supported zoom value of this device.
  ///
  /// - Note: Depending on the ``Constraint``s and
  /// ``CameraOutput``s configured on the
  /// ``CameraSession``, the actual maximum zoom
  /// value may change.
  /// Inspect the returned ``CameraController``'s
  /// ``CameraController/maxZoom`` property
  /// for a true current maximum.
  public var maxZoom: Double {
    return device.maxAvailableVideoZoomFactor
  }

  /// If this ``CameraDevice`` is a virtual device,
  /// this returns a list of zoom factors at which the virtual
  /// device may switch to another physical camera.
  ///
  /// For physical devices, this returns an empty array.
  ///
  /// ```swift
  /// print(device.zoomLensSwitchFactors)
  /// ```
  public var zoomLensSwitchFactors: [Double] {
    return device.virtualDeviceSwitchOverVideoZoomFactors.map { $0.doubleValue }
  }

  /// Whether the ``CameraDevice`` supports
  /// distortion correction to correct stretched edges
  /// in wide-angle Cameras during Photo capture.
  /// See ``CapturePhotoSettings/isDistortionCorrectionEnabled``
  public var supportsDistortionCorrection: Bool {
    return device.isGeometricDistortionCorrectionSupported
  }

  /// Gets whether this ``CameraDevice``
  /// supports metering auto-focus (``MeteringMode/af``)
  /// via ``CameraController/focus(at:options:)``.
  public var supportsFocusMetering: Bool {
    return device.isFocusPointOfInterestSupported
      && (device.isFocusModeSupported(.autoFocus) || device.isFocusModeSupported(.continuousAutoFocus))
  }

  /// Whether the device can lock focus at its current lens position.
  ///
  /// See ``CameraController/lockCurrentFocus()``.
  public var supportsFocusLocking: Bool {
    return device.isFocusModeSupported(.locked)
  }

  /// Whether the device accepts an explicit lens position for manual focus.
  ///
  /// See ``CameraController/lockFocus(at:)``.
  public var supportsCustomLensPosition: Bool {
    return device.isLockingFocusWithCustomLensPositionSupported
  }

  /// Gets whether this ``CameraDevice``
  /// supports metering auto-exposure (``MeteringMode/ae``)
  /// via ``CameraController/focus(at:options:)``.
  public var supportsExposureMetering: Bool {
    return device.isExposurePointOfInterestSupported
      && (device.isExposureModeSupported(.autoExpose) || device.isExposureModeSupported(.continuousAutoExposure))
  }

  /// Whether the device can lock its current exposure values.
  ///
  /// See ``CameraController/lockCurrentExposure()``.
  public var supportsExposureLocking: Bool {
    return device.isExposureModeSupported(.locked)
  }

  /// Whether the device accepts an explicit exposure duration and ISO.
  ///
  /// See ``CameraController/lockExposure(duration:iso:)``.
  public var supportsCustomExposure: Bool {
    return device.isExposureModeSupported(.custom)
  }

  /// Gets whether this ``CameraDevice``
  /// supports metering auto-white-balance (``MeteringMode/awb``)
  /// via ``CameraController/focus(at:options:)``.
  public var supportsWhiteBalanceMetering: Bool {
    return device.isWhiteBalanceModeSupported(.autoWhiteBalance)
      || device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance)
  }

  /// Whether the device can lock its current white-balance gains.
  ///
  /// See ``CameraController/lockCurrentWhiteBalance()``.
  public var supportsWhiteBalanceLocking: Bool {
    return device.isWhiteBalanceModeSupported(.locked)
  }

  /// Whether the device accepts explicit red, green, and blue white-balance gains.
  ///
  /// See ``CameraController/lockWhiteBalance(gains:)``.
  public var supportsCustomWhiteBalanceGains: Bool {
    return device.isLockingWhiteBalanceWithCustomDeviceGainsSupported
  }

  /// The maximum supported value for each native white-balance color-channel gain.
  public var maxWhiteBalanceGain: Float {
    return device.maxWhiteBalanceGain
  }

  /// Represents all ``MediaType``s this
  /// ``CameraDevice`` can capture.
  ///
  /// Most Cameras return `[video]`.
  /// Virtual Cameras that also support Depth Capture return `[video, depth]`.
  public var mediaTypes: [MediaType] {
    let allMediaTypes: [MediaType] = [.video, .depth, .metadata]
    return allMediaTypes.filter { device.hasMediaType($0.toAVMediaType()) }
  }

  /// Checks whether this device supports a configuration's native formats and selected constraints.
  ///
  /// This checks frame rate, stabilization, and dynamic range against the selected format. It does not
  /// validate output connections, multi-camera hardware cost, or current system conditions. The session
  /// validates connected outputs during ``CameraSession/configure(_:configuration:)``.
  public func supports(_ config: CameraSessionConfig) -> Bool {
    let format = config.negotiatedFormat.format
    guard device.formats.contains(format) else { return false }
    if let depthFormat = config.negotiatedFormat.depthFormat,
      !format.supportedDepthDataFormats.contains(depthFormat)
    {
      return false
    }

    if let fps = config.selectedFPS {
      guard fps.isFinite, fps > 0, format.videoSupportedFrameRateRanges.contains(where: { $0.contains(fps: fps) }) else { return false }
    }
    for target in [config.selectedVideoStabilizationMode, config.selectedPreviewStabilizationMode].compactMap({ $0 }) {
      guard let nativeMode = target.toAVCaptureVideoStabilizationMode() else { return false }
      if nativeMode != .off && !format.isVideoStabilizationModeSupported(nativeMode) { return false }
    }
    if let dynamicRange = config.selectedVideoDynamicRange {
      guard let nativeColorSpace = dynamicRange.colorSpace.toAVCaptureColorSpace(),
        format.supportedColorSpaces.contains(nativeColorSpace),
        dynamicRange.bitDepth == format.bitDepth,
        dynamicRange.colorRange == format.colorRange
      else { return false }
    }
    return true
  }

  /// Returns whether two values identify the same Camera device.
  public static func == (lhs: CameraDevice, rhs: CameraDevice) -> Bool {
    lhs.id == rhs.id
  }

  /// Hashes the Camera's stable unique identifier.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}
