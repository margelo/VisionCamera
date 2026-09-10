// Copyright © 2025 Marc Rousavy @ Margelo

import CoreMedia

extension PixelFormat {
  init(osType: OSType) {
    self.init(rawValue: osType)
  }

  init(mediaSubType: CMFormatDescription.MediaSubType) {
    self.init(rawValue: mediaSubType.rawValue)
  }
}
