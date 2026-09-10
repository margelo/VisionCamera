///
/// AV+PhotoContainerFormat.swift
/// VisionCamera
/// Copyright © 2025 Marc Rousavy @ Margelo
///

import AVFoundation
import Foundation

extension PhotoContainerFormat {
  init(avFileType: AVFileType) {
    switch avFileType {
    case .dng:
      self = .dng
    case .heic:
      self = .heic
    case .jpg:
      self = .jpeg
    case .tif:
      self = .tiff
    default:
      if #available(iOS 26.0, *) {
        if avFileType == .dcm {
          self = .dcm
          return
        }
      }
      logger.error("Received unknown AVFileType: \(avFileType.rawValue)")
      self = .unknown
    }
  }

  init(settings: AVCapturePhotoSettings) {
    let fileType = settings.rawPhotoPixelFormatType == 0 ? settings.processedFileType : settings.rawFileType
    if let fileType {
      self.init(avFileType: fileType)
    } else {
      self = .unknown
    }
  }

  func toUTType() throws -> UTType {
    switch self {
    case .unknown:
      throw CameraError(message: "Cannot convert \"unknown\" ImageFormat to AVFileType!")
    case .jpeg:
      return .jpeg
    case .heic:
      return .heic
    case .tiff:
      return .tiff
    case .dcm:
      guard let type = UTType(tag: "dcm", tagClass: .filenameExtension, conformingTo: nil) else {
        throw CameraError(
          message: "PhotoContainerFormat \"dcm\" cannot be converted to UTType!")
      }
      return type
    case .dng:
      guard let type = UTType("com.adobe.raw-image") else {
        throw CameraError(message: "The DNG image type is unavailable.")
      }
      return type
    }
  }
}
