// Copyright © 2025 Marc Rousavy @ Margelo

import CoreGraphics
import ImageIO

@available(iOS 16.0, *)
enum BarcodeImageGeometry {
  static func orientedSize(_ size: CGSize, orientation: CGImagePropertyOrientation) -> CGSize {
    switch orientation {
    case .left, .leftMirrored, .right, .rightMirrored:
      return CGSize(width: size.height, height: size.width)
    default:
      return size
    }
  }

}
