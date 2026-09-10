// Copyright © 2025 Marc Rousavy @ Margelo

import UIKit

extension UIImage.Orientation {
  init?(exifValue: UInt32) {
    switch exifValue {
    case 1: self = .up
    case 2: self = .upMirrored
    case 3: self = .down
    case 4: self = .downMirrored
    case 5: self = .leftMirrored
    case 6: self = .right
    case 7: self = .rightMirrored
    case 8: self = .left
    default: return nil
    }
  }

  var isMirrored: Bool {
    switch self {
    case .up, .down, .left, .right: return false
    case .upMirrored, .downMirrored, .leftMirrored, .rightMirrored: return true
    @unknown default: return false
    }
  }
}
