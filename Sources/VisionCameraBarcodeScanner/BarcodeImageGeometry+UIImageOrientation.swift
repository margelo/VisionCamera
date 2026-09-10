// Copyright © 2025 Marc Rousavy @ Margelo

import ImageIO
import UIKit

@available(iOS 16.0, *)
extension BarcodeImageGeometry {
  static func orientation(from orientation: UIImage.Orientation) throws -> CGImagePropertyOrientation {
    switch orientation {
    case .up: return .up
    case .down: return .down
    case .left: return .left
    case .right: return .right
    case .upMirrored: return .upMirrored
    case .downMirrored: return .downMirrored
    case .leftMirrored: return .leftMirrored
    case .rightMirrored: return .rightMirrored
    @unknown default: throw BarcodeScannerError.unsupportedImage
    }
  }
}
