// Copyright © 2025 Marc Rousavy @ Margelo

import CoreImage
import UIKit

extension CIImage {
  private static let imageRenderingContext = CIContext(options: [.useSoftwareRenderer: false])

  func image(orientation: UIImage.Orientation) throws(MediaError) -> UIImage {
    guard let image = Self.imageRenderingContext.createCGImage(self, from: extent) else {
      throw .imageRenderingFailed
    }
    return UIImage(cgImage: image, scale: 1, orientation: orientation)
  }
}
