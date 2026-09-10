// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation

extension AVCapturePhotoSettings {
  func applyQualityPrioritization(_ priority: QualityPrioritization?) throws {
    if AVCapturePhotoOutput.isBayerRAWPixelFormat(rawPhotoPixelFormatType) {
      guard priority == nil || priority == .speed else {
        throw CameraError(message: "Bayer RAW capture supports only speed quality prioritization.")
      }
      photoQualityPrioritization = .speed
    } else if let priority {
      photoQualityPrioritization = priority.toAVQualityPrioritization()
    }
  }
}
