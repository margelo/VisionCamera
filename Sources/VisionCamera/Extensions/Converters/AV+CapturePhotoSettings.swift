///
/// CapturePhotoSettings+toAVCapturePhotoSettings.swift
/// VisionCamera
/// Copyright © 2025 Marc Rousavy @ Margelo
///

import AVFoundation
import CoreLocation
import Foundation

extension AVCapturePhotoSettings {
  private var isRAWFormat: Bool {
    return self.rawPhotoPixelFormatType != 0
  }
  private var isAppleProRAWFormat: Bool {
    return AVCapturePhotoOutput.isAppleProRAWPixelFormat(self.rawPhotoPixelFormatType)
  }

  var supportsQualityPrioritization: Bool {
    if isRAWFormat {
      // It's a RAW format - only Apple ProRAW supports qualityPrioritization
      return isAppleProRAWFormat
    } else {
      // It's NOT a RAW format (eg JPEG or HEIC), we can use qualityPrioritization
      return true
    }
  }
  var supportsDepthData: Bool {
    // If we shoot in RAW, we cannot enable depth data
    return !isRAWFormat
  }
  var supportsDistortionCorrection: Bool {
    // If we shoot in RAW, we cannot enable distortion correction
    return !isRAWFormat
  }
}

extension AVCapturePhotoOutput {
  var bestRawPixelFormat: OSType? {
    if self.isAppleProRAWEnabled {
      if let appleProRawFormat = self.availableRawPhotoPixelFormatTypes.first(where: {
        AVCapturePhotoOutput.isAppleProRAWPixelFormat($0)
      }) {
        // We have an Apple ProRAW format! Use that
        return appleProRawFormat
      }
    }
    // No Apple ProRAW enabled or available, just use the first available default RAW format (or nil if there is none)
    return self.availableRawPhotoPixelFormatTypes.first
  }
}

extension CapturePhotoSettings {
  private func getBaseAVCapturePhotoSettings(
    for output: AVCapturePhotoOutput,
    in containerFormat: TargetPhotoContainerFormat,
    quality: Double
  ) throws -> AVCapturePhotoSettings {
    guard quality >= 0.0 && quality <= 1.0 else {
      throw CaptureError.invalidQuality(quality)
    }

    switch containerFormat {
    case .jpeg:
      return AVCapturePhotoSettings(format: [
        AVVideoCodecKey: AVVideoCodecType.jpeg,
        AVVideoCompressionPropertiesKey: [
          AVVideoQualityKey: quality
        ],
      ])
    case .heic:
      return AVCapturePhotoSettings(format: [
        AVVideoCodecKey: AVVideoCodecType.hevc,
        AVVideoCompressionPropertiesKey: [
          AVVideoQualityKey: quality
        ],
      ])
    case .dng:
      // For RAW, we need to get the first available RAW format (often Bayer14)
      guard let rawFormat = output.bestRawPixelFormat else {
        throw CaptureError.rawCaptureUnsupported
      }
      return AVCapturePhotoSettings(rawPixelFormatType: rawFormat)
    case .native:
      // Apple's default processed photo format is HEIC.
      return try getBaseAVCapturePhotoSettings(for: output, in: .heic, quality: quality)
    }
  }

  /// Converts this `CapturePhotoSettings` config to `AVCapturePhotoSettings`.

  /// This contains some sensible defaults.

  /// - Options that are supported will be applied

  /// - Options that are not supported but don't directly affect results (e.g. `isDistortionCorrectionEnabled`) will be swallowed.

  /// - Options that are not supported but directly affect results (e.g. `isDepthDataEnabled`) will throw.
  func toAVCapturePhotoSettings(
    for output: AVCapturePhotoOutput, withOptions options: PhotoOutputOptions
  ) throws -> AVCapturePhotoSettings {
    let settings = try getBaseAVCapturePhotoSettings(
      for: output,
      in: options.containerFormat,
      quality: options.quality)

    // Shoot in max resolution
    if #available(iOS 16.0, *) {
      settings.maxPhotoDimensions = output.maxPhotoDimensions
    }

    // photoQualityPrioritization can only be set on processed photos.
    if settings.supportsQualityPrioritization {
      // qualityPrioritization is configured on the PhotoOutput itself - for simplicy.
      settings.photoQualityPrioritization = output.maxPhotoQualityPrioritization
    }

    // flashMode={...}
    let avFlashMode = flashMode.toAVCaptureDeviceFlashMode()
    if output.supportedFlashModes.contains(avFlashMode) {
      settings.flashMode = avFlashMode
    }
    // isShutterSoundEnabled={...}
    if let isShutterSoundEnabled {
      if #available(iOS 18.0, *) {
        if output.isShutterSoundSuppressionSupported {
          settings.isShutterSoundSuppressionEnabled = !isShutterSoundEnabled
        }
      }
    }
    // isDepthDataEnabled={...}
    if let isDepthDataEnabled {
      // TODO: This is probably broken since we need to set `output.isDepthDataEnabledDelivery` first,
      //       at init or configuration time (configure(...)), not at each capture.
      guard settings.supportsDepthData else {
        throw CaptureError.depthDataUnavailableForRawPhoto
      }
      if isDepthDataEnabled && !output.isDepthDataDeliverySupported {
        throw CaptureError.depthDataUnsupported
      }
      settings.isDepthDataDeliveryEnabled = isDepthDataEnabled
      settings.embedsDepthDataInPhoto = isDepthDataEnabled
    }
    // isCameraCalibrationDataDeliveryEnabled={...}
    if let isCameraCalibrationDataDeliveryEnabled {
      if isCameraCalibrationDataDeliveryEnabled && !output.isCameraCalibrationDataDeliverySupported {
        throw CaptureError.cameraCalibrationDataUnsupported
      }
      settings.isCameraCalibrationDataDeliveryEnabled = isCameraCalibrationDataDeliveryEnabled
    }
    // isRedEyeReductionEnabled={...}
    if let isRedEyeReductionEnabled {
      if output.isAutoRedEyeReductionSupported {
        settings.isAutoRedEyeReductionEnabled = isRedEyeReductionEnabled
      }
    }
    // isDistortionCorrectionEnabled={...}
    if let isDistortionCorrectionEnabled {
      if settings.supportsDistortionCorrection && output.isContentAwareDistortionCorrectionSupported {
        settings.isAutoContentAwareDistortionCorrectionEnabled = isDistortionCorrectionEnabled
      }
    }
    // isVirtualDeviceFusionEnabled={...}
    if let isVirtualDeviceFusionEnabled {
      if output.isVirtualDeviceFusionSupported {
        settings.isAutoVirtualDeviceFusionEnabled = isVirtualDeviceFusionEnabled
      }
    }
    // previewPhotoTargetSize={...}
    if let previewImageTargetSize = options.previewImageTargetSize {
      // Preview image requested - choose default format
      if let previewFormat = settings.availablePreviewPhotoPixelFormatTypes.first {
        settings.previewPhotoFormat = [
          kCVPixelBufferPixelFormatTypeKey as String: previewFormat,
          kCVPixelBufferWidthKey as String: Int(previewImageTargetSize.width),
          kCVPixelBufferHeightKey as String: Int(previewImageTargetSize.height),
        ]
      }
    }
    // metadata
    settings.addLibraryMetadataTag()
    if let location {
      settings.addLocationMetadataTag(location)
    }

    return settings
  }
}

extension AVCapturePhotoSettings {
  fileprivate func addLibraryMetadataTag() {
    var metadataCopy = metadata
    var tiff = metadataCopy[kCGImagePropertyTIFFDictionary as String] as? [String: Any] ?? [:]
    tiff[kCGImagePropertyTIFFSoftware as String] = "VisionCamera"
    metadataCopy[kCGImagePropertyTIFFDictionary as String] = tiff
    self.metadata = metadataCopy
  }
  fileprivate func addLocationMetadataTag(_ location: CLLocation) {
    var metadataCopy = metadata
    let gps = location.toEXIF()
    metadataCopy[kCGImagePropertyGPSDictionary as String] = gps
    self.metadata = metadataCopy
  }
}
