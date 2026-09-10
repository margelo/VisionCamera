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
public final class CameraDevice {
  /// The underlying AVFoundation capture device.
  public let device: AVCaptureDevice

  /// Creates a Camera device from an existing `AVCaptureDevice`.
  public init(device: AVCaptureDevice) {
    self.device = device
  }

  /// Get a list of all supported ``PixelFormat``s this
  /// ``CameraDevice`` can stream in.
  public lazy var supportedPixelFormats: [PixelFormat] = {
    let videoFormats = device.formats
    let depthFormats = device.formats.flatMap { $0.supportedDepthDataFormats }
    let allFormats = videoFormats + depthFormats
    return
      allFormats
      .map { PixelFormat(mediaSubType: $0.formatDescription.mediaSubType) }
      .withoutDuplicates()
  }()

  /// Get a list of all supported resolutions this ``CameraDevice``
  /// can produce for outputs of the given ``OutputStreamType``.
  ///
  /// If a given ``OutputStreamType`` can not be streamed to at
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
  /// See ``DepthFrameOutputOptions/targetResolution``
  /// See ``ResolutionBiasConstraint``
  ///
  /// ```swift
  /// let resolutions = device.getSupportedResolutions(outputStreamType: .photo)
  /// ```
  public func getSupportedResolutions(outputStreamType: OutputStreamType) -> [Size] {
    let streamType = streamType(from: outputStreamType)
    return device.formats
      .flatMap { $0.supportedResolutions(for: streamType) }
      .withoutDuplicates()
      .map { Size(dimensions: $0) }
  }
  private func streamType(from outputStreamType: OutputStreamType) -> StreamType {
    switch outputStreamType {
    case .photo:
      return .photo
    case .video, .stream:
      return .video
    case .depthPhoto:
      return .depthPhoto
    case .depthStream:
      return .depthVideo
    }
  }

  /// Gets all available Frame Rate Ranges this
  /// ``CameraDevice`` supports individually.
  ///
  /// Frame Rates are expressed in FPS (Frames per Second),
  /// for example `60` refers to 60 FPS (= 16.666ms per Frame).
  ///
  /// Use ``CameraDevice/supportsFPS(fps:)`` as a convenience
  /// method to find out if a given fixed frame rate is supported
  /// individually.
  ///
  /// While a device may support a given FPS ``CameraRange``
  /// individually, it is not guaranteed to be supported with all
  /// possible feature and output combinations.
  ///
  /// The ``Constraint`` API (specifically ``FPSConstraint``)
  /// internally negotiates the target ``FPSConstraint/fps``
  /// with other enabled features (such as ``VideoStabilizationModeConstraint``)
  /// and all connected ``CameraOutput``s to find a best-matching
  /// supported combination on this device.
  ///
  /// Alternatively, to find out if a specific combination is supported upfront,
  /// use the ``CameraDevice/isSessionConfigSupported(config:)``
  /// method with your desired outputs and constraints applied.
  public lazy var supportedFPSRanges: [CameraRange] = {
    return device.formats
      .flatMap { $0.videoSupportedFrameRateRanges }
      .withoutDuplicates()
      .map { CameraRange(range: $0) }
  }()

  /// Gets whether this ``CameraDevice``
  /// supports capturing Photos in High Dynamic Range (HDR).
  ///
  /// Photo HDR captures multiple images in various
  /// exposure settings (often one under-exposed, one
  /// over-exposed and one perfectly exposed), and fuses
  /// the images together into a single image with a wider
  /// range of colors, which results in darker blacks and
  /// brighter whites.
  ///
  /// While a device may support Photo HDR individually,
  /// it is not guaranteed to be supported with all
  /// possible feature and output combinations.
  ///
  /// The ``Constraint`` API (specifically ``PhotoHDRConstraint``)
  /// internally negotiates the target Photo HDR preference with
  /// other enabled features (such as ``ResolutionBiasConstraint``)
  /// and all connected ``CameraOutput``s to find a best-matching
  /// supported combination on this device.
  ///
  /// Alternatively, to find out if a specific combination is supported upfront,
  /// use the ``CameraDevice/isSessionConfigSupported(config:)``
  /// method with your desired outputs and constraints applied.
  ///
  /// See ``PhotoHDRConstraint/photoHDR``
  /// See ``CameraPhotoOutput``
  public let supportsPhotoHDR: Bool = false

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
  /// The ``Constraint`` API (specifically ``VideoDynamicRangeConstraint``)
  /// internally negotiates the target Dynamic Range with
  /// other enabled features (such as ``ResolutionBiasConstraint`` or
  /// ``FPSConstraint``) and all connected ``CameraOutput``s
  /// to find a best-matching supported combination on this device.
  ///
  /// Alternatively, to find out if a specific combination is supported upfront,
  /// use the ``CameraDevice/isSessionConfigSupported(config:)``
  /// method with your desired outputs and constraints applied.
  ///
  /// See ``VideoDynamicRangeConstraint/videoDynamicRange``
  /// See ``CameraVideoOutput``
  public lazy var supportedVideoDynamicRanges: [DynamicRange] = {
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
  }()

  /// Returns whether this ``CameraDevice``
  /// supports streaming to the given `output`.
  ///
  /// Usually, a ``CameraDevice`` can stream to all
  /// ``CameraOutput``s, with very rare exceptions.
  ///
  /// For example, Depth Frame Outputs (``CameraDepthFrameOutput``)
  /// may not be supported on all ``CameraDevice``s - see
  /// ``CameraDevice/mediaTypes``.
  public func supportsOutput(output: any CameraOutput) -> Bool {
    guard let output = output as? any NativeCameraOutput else {
      // Not a NativeCameraOutput!
      return false
    }
    return device.formats.contains { $0.supportsOutput(output.output) }
  }

  /// Gets whether the given `fps` is individually supported
  /// by any of the ``CameraDevice/supportedFPSRanges`` on this ``CameraDevice``.
  ///
  /// While a device may support a given FPS ``CameraRange``
  /// individually, it is not guaranteed to be supported with all
  /// possible feature and output combinations.
  ///
  /// The ``Constraint`` API (specifically ``FPSConstraint``)
  /// internally negotiates the target ``FPSConstraint/fps``
  /// with other enabled features (such as ``VideoStabilizationModeConstraint``)
  /// and all connected ``CameraOutput``s to find a best-matching
  /// supported combination on this device.
  ///
  /// Alternatively, to find out if a specific combination is supported upfront,
  /// use the ``CameraDevice/isSessionConfigSupported(config:)``
  /// method with your desired outputs and constraints applied.
  ///
  /// See ``CameraDevice/supportedFPSRanges``
  public func supportsFPS(fps: Double) -> Bool {
    return supportedFPSRanges.contains { range in
      fps >= range.min && fps <= range.max
    }
  }

  /// Returns whether this ``CameraDevice`` supports
  /// the given `StabilizationMode` for video streams
  /// (e.g. ``CameraVideoOutput``).
  ///
  /// While a device may support a given `StabilizationMode`
  /// individually, it is not guaranteed to be supported with all
  /// possible feature and output combinations.
  ///
  /// The ``Constraint`` API (specifically
  /// ``VideoStabilizationModeConstraint``) internally
  /// negotiates the target ``VideoStabilizationModeConstraint/videoStabilizationMode``
  /// with other enabled features (such as ``FPSConstraint``) and
  /// all connected ``CameraOutput``s to find a best-matching
  /// supported combination on this device.
  ///
  /// Alternatively, to find out if a specific combination is supported upfront,
  /// use the ``CameraDevice/isSessionConfigSupported(config:)``
  /// method with your desired outputs and constraints applied.
  public func supportsVideoStabilizationMode(videoStabilizationMode: TargetStabilizationMode) -> Bool {
    let stabilizationMode = videoStabilizationMode.toAVCaptureVideoStabilizationMode()
    return device.formats.contains { $0.isVideoStabilizationModeSupported(stabilizationMode) }
  }

  /// Returns whether this ``CameraDevice`` supports
  /// the given `StabilizationMode` for preview streams
  /// (e.g. ``CameraPreviewOutput``).
  ///
  /// While a device may support a given `StabilizationMode`
  /// individually, it is not guaranteed to be supported with all
  /// possible feature and output combinations.
  ///
  /// The ``Constraint`` API (specifically
  /// ``PreviewStabilizationModeConstraint``) internally
  /// negotiates the target ``PreviewStabilizationModeConstraint/previewStabilizationMode``
  /// with other enabled features (such as ``FPSConstraint``) and
  /// all connected ``CameraOutput``s to find a best-matching
  /// supported combination on this device.
  ///
  /// Alternatively, to find out if a specific combination is supported upfront,
  /// use the ``CameraDevice/isSessionConfigSupported(config:)``
  /// method with your desired outputs and constraints applied.
  public func supportsPreviewStabilizationMode(previewStabilizationMode: TargetStabilizationMode) -> Bool {
    // Video and Preview stabilization flows through the same connection on iOS.
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
      // On iOS, Position "external" is for some reason reflected on the .deviceType, not on .position.
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
  public lazy var physicalDevices: [CameraDevice] =
    device.constituentDevices.map { CameraDevice(device: $0) }

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

  /// Returns the Camera Device's nominal focal length in 35mm film format.
  public var focalLength: Double? {
    guard #available(iOS 26.0, *) else {
      return nil
    }
    return Double(device.nominalFocalLengthIn35mmFilm)
  }

  /// The size (ƒ number) of the lens diaphragm.
  public var lensAperture: Double {
    return Double(device.lensAperture)
  }

  /// Returns `true` if this camera is a Continuity Camera.
  /// On non iOS platforms this is always `false`.
  public var isContinuityCamera: Bool {
    guard #available(iOS 16.0, *) else {
      return false
    }
    return device.isContinuityCamera
  }

  /// The matching Desk View camera for this Continuity Camera, if available.
  public var companionDeskViewCamera: (CameraDevice)? {
    guard #available(iOS 16.0, *) else {
      return nil
    }
    guard let companion = device.companionDeskViewCamera else {
      return nil
    }
    return CameraDevice(device: companion)
  }

  /// Gets whether this ``CameraDevice``
  /// supports smoothly adjusting focus via
  /// ``CameraControllerConfiguration/enableSmoothAutoFocus``.
  ///
  /// ```swift
  /// try await controller.configure(config: CameraControllerConfiguration(
  ///   enableSmoothAutoFocus: device.supportsSmoothAutoFocus
  /// ))
  /// ```
  public var supportsSmoothAutoFocus: Bool {
    return device.isSmoothAutoFocusSupported
  }

  /// Returns `true` if this ``CameraDevice`` supports
  /// capturing photos with the ``QualityPrioritization/speed``
  /// ``QualityPrioritization``.
  ///
  /// See ``PhotoOutputOptions/qualityPrioritization``
  public var supportsSpeedQualityPrioritization: Bool {
    // iOS always supports QualityPrioritization.speed
    return true
  }

  /// Gets whether this ``CameraDevice``
  /// supports biasing auto-exposure via
  /// ``CameraController/setExposureBias(exposure:)``.
  public var supportsExposureBias: Bool {
    return true
  }
  /// Gets the minimum supported value for
  /// the exposure bias (in EV units), or `0`
  /// if ``CameraDevice/supportsExposureBias`` is false.
  public var minExposureBias: Double {
    return Double(device.minExposureTargetBias)
  }
  /// Gets the maximum supported value for
  /// the exposure bias (in EV units), or `0`
  /// if ``CameraDevice/supportsExposureBias`` is false.
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

  /// Whether this ``CameraDevice`` supports
  /// using its flash (``CameraDevice/hasFlash``) as a
  /// continuous light (_"torch"_) while the session is running.
  ///
  /// In almost all cases, ``CameraDevice/hasTorch`` is the
  /// same as ``CameraDevice/hasFlash``.
  ///
  /// Use ``CameraDevice/supportsTorchStrength`` to find out whether
  /// the torch additionally accepts a custom brightness level
  /// via ``CameraController/enableTorchWithStrength(strength:)``.
  ///
  /// See ``CameraController/setTorchMode(mode:)``
  /// See ``CameraDevice/supportsTorchStrength``
  public var hasTorch: Bool {
    return device.hasTorch
  }

  /// Whether this ``CameraDevice`` supports configuring
  /// a custom torch brightness level via
  /// ``CameraController/enableTorchWithStrength(strength:)``.
  ///
  /// Many devices with a ``CameraDevice/hasTorch`` can only
  /// toggle the torch on or off and do not expose a brightness
  /// level - calling
  /// ``CameraController/enableTorchWithStrength(strength:)``
  /// on such a device will fail. Use
  /// ``CameraController/setTorchMode(mode:)``
  /// instead to turn the torch on at the system default level.
  ///
  /// See ``CameraDevice/hasTorch``
  /// See ``CameraController/enableTorchWithStrength(strength:)``
  public var supportsTorchStrength: Bool {
    // On iOS device with a torch also supports custom torch level/strength
    return device.hasTorch
  }

  /// Gets the minimum supported torch strength for this device,
  /// or `0` if ``CameraDevice/supportsTorchStrength`` is false.
  ///
  /// Use ``CameraController/enableTorchWithStrength(strength:)``
  /// to set the torch strength.
  ///
  /// See ``CameraDevice/supportsTorchStrength``
  /// See ``CameraDevice/maxTorchStrength``
  public var minTorchStrength: Double {
    return device.minTorchStrength
  }

  /// Gets the maximum supported torch strength for this device,
  /// or `0` if ``CameraDevice/supportsTorchStrength`` is false.
  ///
  /// Use ``CameraController/enableTorchWithStrength(strength:)``
  /// to set the torch strength.
  ///
  /// See ``CameraDevice/supportsTorchStrength``
  /// See ``CameraDevice/minTorchStrength``
  public var maxTorchStrength: Double {
    return device.maxTorchStrength
  }

  /// Whether this ``CameraDevice`` supports
  /// enabling low-light boost to improve exposure in
  /// dark scenes via ``CameraControllerConfiguration/enableLowLightBoost``.
  ///
  /// ```swift
  /// try await controller.configure(config: CameraControllerConfiguration(
  ///   enableLowLightBoost: device.supportsLowLightBoost
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
  /// See ``CapturePhotoSettings/enableDistortionCorrection``
  public var supportsDistortionCorrection: Bool {
    return device.isGeometricDistortionCorrectionSupported
  }

  /// Returns `true` if this ``CameraDevice`` supports
  /// delivering preview `UIImage` instances before
  /// the actual ``Photo`` is available.
  ///
  /// On iOS, this is always `true`.
  ///
  /// See ``PhotoOutputOptions/previewImageTargetSize``
  /// See ``CapturePhotoCallbacks/onPreviewImageAvailable``
  public var supportsPreviewImage: Bool {
    return true
  }

  /// Gets whether this ``CameraDevice``
  /// supports metering auto-focus (``MeteringMode/af``)
  /// via ``CameraController/focusTo(point:options:)``.
  public var supportsFocusMetering: Bool {
    return device.isFocusModeSupported(.autoFocus)
      || device.isFocusModeSupported(.continuousAutoFocus)
  }

  /// Gets whether this ``CameraDevice``
  /// supports manual focus via
  /// ``CameraController/setFocusLocked(lensPosition:)``.
  public var supportsFocusLocking: Bool {
    return device.isLockingFocusWithCustomLensPositionSupported
  }

  /// Gets whether this ``CameraDevice``
  /// supports metering auto-exposure (``MeteringMode/ae``)
  /// via ``CameraController/focusTo(point:options:)``.
  public var supportsExposureMetering: Bool {
    return device.isExposureModeSupported(.autoExpose)
      || device.isExposureModeSupported(.continuousAutoExposure)
  }

  /// Gets whether this ``CameraDevice``
  /// supports manual exposure via
  /// ``CameraController/setExposureLocked(duration:iso:)``.
  public var supportsExposureLocking: Bool {
    return device.isExposureModeSupported(.custom)
  }

  /// Gets whether this ``CameraDevice``
  /// supports metering auto-white-balance (``MeteringMode/awb``)
  /// via ``CameraController/focusTo(point:options:)``.
  public var supportsWhiteBalanceMetering: Bool {
    return device.isWhiteBalanceModeSupported(.autoWhiteBalance)
      || device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance)
  }

  /// Gets whether this ``CameraDevice``
  /// supports manual white-balance via
  /// ``CameraController/setWhiteBalanceLocked(whiteBalanceGains:)``.
  ///
  /// See ``CameraDevice/maxWhiteBalanceGain``
  public var supportsWhiteBalanceLocking: Bool {
    return device.isLockingWhiteBalanceWithCustomDeviceGainsSupported
  }

  /// The maximum value a single color-channel can be
  /// set to in ``WhiteBalanceGains``, or `0`
  /// if ``CameraDevice/supportsWhiteBalanceLocking`` is `false`.
  public var maxWhiteBalanceGain: Double {
    return Double(device.maxWhiteBalanceGain)
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

  /// Returns whether the given ``CameraSessionConfig``
  /// is supported by this ``CameraDevice``, or not.
  ///
  /// If this method returns `false`, configuring a
  /// ``CameraSession`` with this ``CameraSessionConfig``
  /// will fail.
  public func isSessionConfigSupported(config: CameraSessionConfig) -> Bool {
    let format = config.negotiatedFormat.format
    guard device.formats.contains(format) else {
      // Format is from a different `AVCaptureDevice`
      return false
    }

    if let depthFormat = config.negotiatedFormat.depthFormat {
      guard format.supportedDepthDataFormats.contains(depthFormat) else {
        // Format is from a different `AVCaptureDevice.Format`
        return false
      }
    }

    // TODO: Re-use the logic from `ConstraintResolver` for resolving the actual enabled
    //       constraints (like FPS or HDR settings) so we have a single source of truth
    //       when we modify anything in the future.
    //       I guess we should be able to call `ConstraintResolver` with this given `format`
    //       and `depthFormat` (and outputs?) and check if penalty is `0`? Or some strict
    //       comparison without allowing downgrades here.

    if let targetFPS = config.enabledConstraints.selectedFPS {
      let isFPSRangeSupported = format.videoSupportedFrameRateRanges.contains { $0.contains(fps: targetFPS) }
      guard isFPSRangeSupported else {
        // FPS is not supported in Format
        return false
      }
    }

    // TODO: Add other checks here for `config.enabledConstraints`.
    //       We probably also want to compare against Outputs right?
    //       E.g. Return `false` if the `format.unsupportedCaptureOutputClasses` contains of our Output classes.

    return true
  }
}
