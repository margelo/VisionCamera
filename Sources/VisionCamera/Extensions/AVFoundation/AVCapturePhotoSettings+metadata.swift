// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation
import CoreLocation
import ImageIO

extension AVCapturePhotoSettings {
  func addMetadata(location: CLLocation?) {
    var metadata = self.metadata
    var tiff = metadata[kCGImagePropertyTIFFDictionary as String] as? [String: Any] ?? [:]
    tiff[kCGImagePropertyTIFFSoftware as String] = "VisionCamera"
    metadata[kCGImagePropertyTIFFDictionary as String] = tiff
    if let location { metadata[kCGImagePropertyGPSDictionary as String] = location.toEXIF() }
    self.metadata = metadata
  }
}
