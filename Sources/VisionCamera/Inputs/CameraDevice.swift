///
/// CameraDevice.swift
/// VisionCamera
/// Copyright © 2025 Marc Rousavy @ Margelo
///

import AVFoundation
import Foundation

public final class CameraDevice {
  public let device: AVCaptureDevice

  public init(device: AVCaptureDevice) {
    self.device = device
  }

  public lazy var supportedPixelFormats: [PixelFormat] = {
    let videoFormats = device.formats
    let depthFormats = device.formats.flatMap { $0.supportedDepthDataFormats }
    let allFormats = videoFormats + depthFormats
    return
      allFormats
      .map { PixelFormat(mediaSubType: $0.formatDescription.mediaSubType) }
      .withoutDuplicates()
  }()

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

  public lazy var supportedFPSRanges: [CameraRange] = {
    return device.formats
      .flatMap { $0.videoSupportedFrameRateRanges }
      .withoutDuplicates()
      .map { CameraRange(range: $0) }
  }()

  public let supportsPhotoHDR: Bool = false

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

  public func supportsOutput(output: any CameraOutput) -> Bool {
    guard let output = output as? any NativeCameraOutput else {
      // Not a NativeCameraOutput!
      return false
    }
    return device.formats.contains { $0.supportsOutput(output.output) }
  }

  public func supportsFPS(fps: Double) -> Bool {
    return supportedFPSRanges.contains { range in
      fps >= range.min && fps <= range.max
    }
  }

  public func supportsVideoStabilizationMode(videoStabilizationMode: TargetStabilizationMode) -> Bool {
    let stabilizationMode = videoStabilizationMode.toAVCaptureVideoStabilizationMode()
    return device.formats.contains { $0.isVideoStabilizationModeSupported(stabilizationMode) }
  }

  public func supportsPreviewStabilizationMode(previewStabilizationMode: TargetStabilizationMode) -> Bool {
    // Video and Preview stabilization flows through the same connection on iOS.
    return supportsVideoStabilizationMode(videoStabilizationMode: previewStabilizationMode)
  }

  public var id: String {
    return device.uniqueID
  }

  public var modelID: String {
    return device.modelID
  }

  public var localizedName: String {
    return device.localizedName
  }

  public var manufacturer: String {
    return device.manufacturer
  }

  public var type: DeviceType {
    return DeviceType(type: device.deviceType)
  }

  public var position: CameraPosition {
    if #available(iOS 17.0, *) {
      // On iOS, Position "external" is for some reason reflected on the .deviceType, not on .position.
      if device.deviceType == .external || device.deviceType == .continuityCamera {
        return .external
      }
    }
    return CameraPosition(position: device.position)
  }

  public lazy var physicalDevices: [CameraDevice] =
    device.constituentDevices.map { CameraDevice(device: $0) }

  public var isVirtualDevice: Bool {
    return device.isVirtualDevice
  }

  public var focalLength: Double? {
    guard #available(iOS 26.0, *) else {
      return nil
    }
    return Double(device.nominalFocalLengthIn35mmFilm)
  }

  public var lensAperture: Double {
    return Double(device.lensAperture)
  }

  public var isContinuityCamera: Bool {
    guard #available(iOS 16.0, *) else {
      return false
    }
    return device.isContinuityCamera
  }

  public var companionDeskViewCamera: (CameraDevice)? {
    guard #available(iOS 16.0, *) else {
      return nil
    }
    guard let companion = device.companionDeskViewCamera else {
      return nil
    }
    return CameraDevice(device: companion)
  }

  public var supportsSmoothAutoFocus: Bool {
    return device.isSmoothAutoFocusSupported
  }

  public var supportsSpeedQualityPrioritization: Bool {
    // iOS always supports QualityPrioritization.speed
    return true
  }

  public var supportsExposureBias: Bool {
    return true
  }
  public var minExposureBias: Double {
    return Double(device.minExposureTargetBias)
  }
  public var maxExposureBias: Double {
    return Double(device.maxExposureTargetBias)
  }

  public var hasFlash: Bool {
    return device.hasFlash
  }

  public var hasTorch: Bool {
    return device.hasTorch
  }

  public var supportsTorchStrength: Bool {
    // On iOS device with a torch also supports custom torch level/strength
    return device.hasTorch
  }

  public var minTorchStrength: Double {
    return device.minTorchStrength
  }

  public var maxTorchStrength: Double {
    return device.maxTorchStrength
  }

  public var supportsLowLightBoost: Bool {
    return device.isLowLightBoostSupported
  }

  public var minZoom: Double {
    return device.minAvailableVideoZoomFactor
  }

  public var maxZoom: Double {
    return device.maxAvailableVideoZoomFactor
  }

  public var zoomLensSwitchFactors: [Double] {
    return device.virtualDeviceSwitchOverVideoZoomFactors.map { $0.doubleValue }
  }

  public var supportsDistortionCorrection: Bool {
    return device.isGeometricDistortionCorrectionSupported
  }

  public var supportsPreviewImage: Bool {
    return true
  }

  public var supportsFocusMetering: Bool {
    return device.isFocusModeSupported(.autoFocus)
      || device.isFocusModeSupported(.continuousAutoFocus)
  }

  public var supportsFocusLocking: Bool {
    return device.isLockingFocusWithCustomLensPositionSupported
  }

  public var supportsExposureMetering: Bool {
    return device.isExposureModeSupported(.autoExpose)
      || device.isExposureModeSupported(.continuousAutoExposure)
  }

  public var supportsExposureLocking: Bool {
    return device.isExposureModeSupported(.custom)
  }

  public var supportsWhiteBalanceMetering: Bool {
    return device.isWhiteBalanceModeSupported(.autoWhiteBalance)
      || device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance)
  }

  public var supportsWhiteBalanceLocking: Bool {
    return device.isLockingWhiteBalanceWithCustomDeviceGainsSupported
  }

  public var maxWhiteBalanceGain: Double {
    return Double(device.maxWhiteBalanceGain)
  }

  public var mediaTypes: [MediaType] {
    let allMediaTypes: [MediaType] = [.video, .depth, .metadata]
    return allMediaTypes.filter { device.hasMediaType($0.toAVMediaType()) }
  }

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
