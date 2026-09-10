// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation

extension CapturePhotoSettings {
  func toAVCapturePhotoSettings(
    for output: AVCapturePhotoOutput, withOptions options: PhotoOutputOptions
  ) throws -> AVCapturePhotoSettings {
    let settings = try options.containerFormat.captureSettings(for: output)
    let isRAW = settings.rawPhotoPixelFormatType != 0
    let isBayerRAW = AVCapturePhotoOutput.isBayerRAWPixelFormat(settings.rawPhotoPixelFormatType)

    if #available(iOS 16.0, *) {
      settings.maxPhotoDimensions = output.maxPhotoDimensions
    } else {
      settings.isHighResolutionPhotoEnabled = output.isHighResolutionCaptureEnabled
    }
    try settings.applyQualityPrioritization(options.qualityPrioritization)
    if isBayerRAW, let connection = output.connection(with: .video) {
      guard connection.videoScaleAndCropFactor == 1,
        connection.deviceInput?.device.videoZoomFactor == 1
      else {
        throw CaptureError.rawRequiresUnitZoom
      }
    }
    do {
      let nativeFlashMode = flashMode.toAVCaptureDeviceFlashMode()
      guard output.supportedFlashModes.contains(nativeFlashMode) else {
        throw CaptureError.flashModeUnsupported
      }
      settings.flashMode = nativeFlashMode
    }
    if isShutterSoundEnabled == false {
      guard #available(iOS 18.0, *), output.isShutterSoundSuppressionSupported else {
        throw CaptureError.shutterSoundSuppressionUnsupported
      }
      settings.isShutterSoundSuppressionEnabled = true
    }
    if let isDepthDataEnabled {
      if isDepthDataEnabled {
        guard !isRAW, output.isDepthDataDeliverySupported, output.isDepthDataDeliveryEnabled else {
          throw CaptureError.depthDataUnsupported
        }
      }
      settings.isDepthDataDeliveryEnabled = isDepthDataEnabled
      settings.embedsDepthDataInPhoto = isDepthDataEnabled
    }
    if let isRedEyeReductionEnabled {
      guard !isRedEyeReductionEnabled || (!isRAW && output.isAutoRedEyeReductionSupported) else {
        throw CaptureError.redEyeReductionUnsupported
      }
      settings.isAutoRedEyeReductionEnabled = isRedEyeReductionEnabled
    }
    if let isDistortionCorrectionEnabled {
      guard !isDistortionCorrectionEnabled || (!isRAW && output.isContentAwareDistortionCorrectionSupported) else {
        throw CaptureError.distortionCorrectionUnsupported
      }
      settings.isAutoContentAwareDistortionCorrectionEnabled = isDistortionCorrectionEnabled
    }
    if let isVirtualDeviceFusionEnabled {
      guard !isVirtualDeviceFusionEnabled || (!isRAW && output.isVirtualDeviceFusionSupported) else {
        throw CaptureError.virtualDeviceFusionUnsupported
      }
      settings.isAutoVirtualDeviceFusionEnabled = isVirtualDeviceFusionEnabled
    }
    if let size = options.previewImageTargetSize {
      guard let width = Int(exactly: size.width), let height = Int(exactly: size.height), width > 0, height > 0 else {
        throw CaptureError.invalidPreviewDimensions
      }
      guard let format = settings.availablePreviewPhotoPixelFormatTypes.first else {
        throw CaptureError.previewImagesUnsupported
      }
      settings.previewPhotoFormat = [
        kCVPixelBufferPixelFormatTypeKey as String: format,
        kCVPixelBufferWidthKey as String: width,
        kCVPixelBufferHeightKey as String: height,
      ]
    }
    settings.addMetadata(location: location)
    return settings
  }
}
