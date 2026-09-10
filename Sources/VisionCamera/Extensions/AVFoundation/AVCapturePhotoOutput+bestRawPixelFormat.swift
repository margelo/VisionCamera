// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation

extension AVCapturePhotoOutput {
  var bestRawPixelFormat: OSType? {
    if isAppleProRAWEnabled,
      let format = availableRawPhotoPixelFormatTypes.first(where: AVCapturePhotoOutput.isAppleProRAWPixelFormat)
    {
      return format
    }
    return availableRawPhotoPixelFormatTypes.first
  }
}
