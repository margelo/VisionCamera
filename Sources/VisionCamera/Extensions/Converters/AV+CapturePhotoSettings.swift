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
        throw CameraError(message: "Bayer RAW capture requires a device zoom factor and connection scale factor of 1.")
      }
    }
    if let flashMode {
      let nativeFlashMode = flashMode.toAVCaptureDeviceFlashMode()
      guard output.supportedFlashModes.contains(nativeFlashMode) else {
        throw CameraError(message: "The requested flash mode is not supported by this photo output.")
      }
      settings.flashMode = nativeFlashMode
    }
    if enableShutterSound == false {
      guard #available(iOS 18.0, *), output.isShutterSoundSuppressionSupported else {
        throw CameraError(message: "Shutter sound suppression is not supported by this photo output.")
      }
      settings.isShutterSoundSuppressionEnabled = true
    }
    if let enableDepthData {
      if enableDepthData {
        guard !isRAW, output.isDepthDataDeliverySupported, output.isDepthDataDeliveryEnabled else {
          throw CameraError(message: "Depth capture requires a processed format and PhotoOutputOptions.enableDepthDataDelivery.")
        }
      }
      settings.isDepthDataDeliveryEnabled = enableDepthData
      settings.embedsDepthDataInPhoto = enableDepthData
    }
    if let enableRedEyeReduction {
      guard !enableRedEyeReduction || (!isRAW && output.isAutoRedEyeReductionSupported) else {
        throw CameraError(message: "Red-eye reduction is not supported by this photo output.")
      }
      settings.isAutoRedEyeReductionEnabled = enableRedEyeReduction
    }
    if let enableDistortionCorrection {
      guard !enableDistortionCorrection || (!isRAW && output.isContentAwareDistortionCorrectionSupported) else {
        throw CameraError(message: "Distortion correction is not supported by this photo format and output.")
      }
      settings.isAutoContentAwareDistortionCorrectionEnabled = enableDistortionCorrection
    }
    if let enableVirtualDeviceFusion {
      guard !enableVirtualDeviceFusion || (!isRAW && output.isVirtualDeviceFusionSupported) else {
        throw CameraError(message: "Virtual device fusion is not supported by this photo format and output.")
      }
      settings.isAutoVirtualDeviceFusionEnabled = enableVirtualDeviceFusion
    }
    if let size = options.previewImageTargetSize {
      guard let width = Int(exactly: size.width), let height = Int(exactly: size.height), width > 0, height > 0 else {
        throw CameraError(message: "Preview image dimensions must be positive whole pixels.")
      }
      guard let format = settings.availablePreviewPhotoPixelFormatTypes.first else {
        throw CameraError(message: "The selected photo format does not support preview images.")
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
