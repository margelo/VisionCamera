// Copyright © 2025 Marc Rousavy @ Margelo

import CoreMedia
import Foundation

extension RecorderSettings {
  func validate() throws {
    if let maxDuration {
      guard maxDuration.isFinite, maxDuration > 0 else {
        throw CameraError(message: "The maximum recording duration must be finite and positive.")
      }
      let duration = CMTime(seconds: maxDuration, preferredTimescale: 600)
      guard duration.isNumeric, CMTimeCompare(duration, .zero) > 0 else {
        throw CameraError(message: "The maximum recording duration must be representable as a positive time at 600 ticks per second.")
      }
    }
    if let maxFileSize, maxFileSize <= 0 {
      throw CameraError(message: "The maximum recording file size must be positive.")
    }
    if let filePath, !filePath.hasPrefix("/") {
      throw CameraError(message: "The recording destination must be an absolute filesystem path.")
    }
  }
}
