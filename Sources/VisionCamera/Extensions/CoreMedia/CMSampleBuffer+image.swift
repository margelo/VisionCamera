// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation
import CoreImage
import Foundation
import UIKit

extension CMSampleBuffer {
  func image(orientation: UIImage.Orientation) throws(MediaError) -> UIImage {
    guard CMSampleBufferIsValid(self) else { throw .invalidSampleBuffer }
    guard let imageBuffer else { throw .missingPixelBuffer }
    let attachments = CMCopyDictionaryOfAttachments(
      allocator: kCFAllocatorDefault, target: self, attachmentMode: kCMAttachmentMode_ShouldPropagate)
    let options = attachments as? [CIImageOption: Any]
    let image = CIImage(cvPixelBuffer: imageBuffer, options: options)
    return try image.image(orientation: orientation)
  }
}
