// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation
import ImageIO
import UIKit

extension AVCapturePhoto {
  var captureMetadata: MediaSampleMetadata {
    get throws(MediaError) {
      let orientationKey = kCGImagePropertyOrientation as String
      guard let value = metadata[orientationKey] as? UInt32 else {
        throw .photoMetadataUnavailable(key: orientationKey)
      }
      guard let imageOrientation = UIImage.Orientation(exifValue: value) else {
        throw .invalidEXIFOrientation(value)
      }
      return MediaSampleMetadata(
        timestamp: timestamp,
        orientation: CameraOrientation(uiOrientation: imageOrientation),
        isMirrored: imageOrientation.isMirrored)
    }
  }
}
