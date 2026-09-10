// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation
import CoreImage
import UIKit

extension AVDepthData {
  func image(orientation: UIImage.Orientation) throws(MediaError) -> UIImage {
    guard let image = CIImage(depthData: self) else { throw .depthImageUnavailable }
    return try image.image(orientation: orientation)
  }
}
