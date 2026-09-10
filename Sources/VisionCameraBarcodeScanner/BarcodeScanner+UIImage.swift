// Copyright © 2026 Marc Rousavy @ Margelo

import UIKit

@available(iOS 16.0, *)
extension BarcodeScanner {
  /// Scans a UIKit image using its image orientation and underlying pixel dimensions.
  ///
  /// Results use pixels, regardless of `UIImage.scale`. Core Image images must have a finite,
  /// nonempty extent. Animated images are scanned using the image's underlying still representation.
  /// - Throws: ``BarcodeScannerError/unsupportedImage`` if no usable image representation exists.
  public func scan(image: UIImage) throws -> [Barcode] {
    let orientation = try BarcodeImageGeometry.orientation(from: image.imageOrientation)
    if let cgImage = image.cgImage {
      return try scan(image: cgImage, orientation: orientation)
    }
    if let ciImage = image.ciImage {
      return try scan(image: ciImage, orientation: orientation)
    }
    throw BarcodeScannerError.unsupportedImage
  }
}
