///
/// AV+PhotoContainerFormat.swift
/// VisionCamera
/// Copyright © 2025 Marc Rousavy @ Margelo
///

import AVFoundation
import Foundation
import UniformTypeIdentifiers

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

  var uniformType: UTType {
    get throws(MediaError) {
      switch self {
      case .unknown:
        throw .unsupportedPhotoContainerFormat(self)
      case .jpeg:
        return .jpeg
      case .heic:
        return .heic
      case .tiff:
        return .tiff
      case .dcm:
        guard let type = UTType(filenameExtension: "dcm") else {
          throw MediaError.unsupportedPhotoContainerFormat(self)
        }
        return type
      case .dng:
        if #available(iOS 18.0, *) {
          return .dng
        }
        guard let type = UTType("com.adobe.raw-image") else {
          throw MediaError.unsupportedPhotoContainerFormat(self)
        }
        return type
      }
    }
  }
}
