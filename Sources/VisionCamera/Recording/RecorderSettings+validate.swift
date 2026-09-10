// Copyright © 2025 Marc Rousavy @ Margelo

import CoreMedia
import Foundation

extension RecorderSettings {
  func validate() throws {
    if let fileURL, !fileURL.isFileURL {
      throw RecordingError.invalidDestination(fileURL)
    }
    if let maxDuration, !maxDuration.isNumeric || maxDuration <= .zero {
      throw RecordingError.invalidDurationLimit(maxDuration)
    }
    if let maxFileSize, maxFileSize <= 0 {
      throw RecordingError.invalidFileSizeLimit(maxFileSize)
    }
  }
}
