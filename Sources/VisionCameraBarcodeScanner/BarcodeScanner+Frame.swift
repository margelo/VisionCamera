// Copyright © 2026 Marc Rousavy @ Margelo

import VisionCamera

@available(iOS 16.0, *)
extension BarcodeScanner {
  /// Scans a Frame using its rotation and mirroring metadata without copying its pixels.
  ///
  /// Call this from the scanner's serial owner queue. The Frame retains its native sample through the call.
  /// Results own their data independently of the Frame. Do not invalidate or mutate the native sample concurrently.
  public func scan(frame: Frame) throws -> [Barcode] {
    guard frame.isValid else { throw MediaError.invalidSampleBuffer }
    guard let pixelBuffer = frame.pixelBuffer else { throw MediaError.missingPixelBuffer }
    let orientation = try BarcodeImageGeometry.orientation(from: frame.metadata.uiImageOrientation)
    return try scan(pixelBuffer: pixelBuffer, orientation: orientation)
  }
}
