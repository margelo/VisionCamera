// Copyright © 2026 Marc Rousavy @ Margelo

import VisionCamera

@available(iOS 16.0, *)
extension BarcodeScanner {
  /// Scans a Frame using its rotation and mirroring metadata without copying its pixels.
  ///
  /// Call this from the Frame's owning queue. Do not dispose or mutate the Frame concurrently.
  /// The caller remains responsible for disposing it after this method returns or throws.
  public func scan(frame: Frame) throws -> [Barcode] {
    let pixelBuffer = try frame.getPixelBuffer()
    let orientation = try BarcodeImageGeometry.orientation(from: frame.metadata.uiImageOrientation)
    return try scan(pixelBuffer: pixelBuffer, orientation: orientation)
  }
}
