// Copyright © 2026 Marc Rousavy @ Margelo
// Adapted from Marc Rousavy's Barcode result API, created 08.02.26.

import CoreGraphics
import Foundation
import Vision

/// An owned snapshot of a barcode detected by Apple's Vision framework.
///
/// Coordinates are pixels in the input image after its orientation and mirroring are applied.
/// The origin is at the top left. They are neither normalized Vision coordinates nor preview-view
/// coordinates. The result remains valid after disposing the input Frame or scanning another image.
@available(iOS 16.0, *)
public struct Barcode {
  /// The Vision symbology of the detected barcode.
  public let format: VNBarcodeSymbology
  /// The decoded text payload, or `nil` when Vision cannot represent the payload as text.
  ///
  /// This is not ML Kit's display value or a classification of Wi-Fi, contact, URL, or other content.
  public let rawValue: String?
  /// Vision's symbology-specific raw payload representation on iOS 17 and later, if available.
  ///
  /// Always `nil` on iOS 16. These bytes are returned unchanged from `VNBarcodeObservation.payloadData`.
  /// They are not necessarily the original message bytes. For example, tested QR results contain
  /// error-corrected codewords with encoding headers and padding. This is not ML Kit's `rawData`,
  /// and encoding ``rawValue`` as UTF-8 does not reproduce it.
  public let payloadData: Data?
  /// The smallest axis-aligned box around the observation, in oriented image pixels.
  ///
  /// Vision can report coordinates outside the image bounds. They are preserved without clipping.
  public let boundingBox: CGRect
  /// The four detected corners in Vision's top-left, top-right, bottom-right, bottom-left order.
  ///
  /// The points use oriented image pixels with a top-left origin. The semantic corner labels refer
  /// to the detected symbol, so a rotated symbol's first point need not be the smallest x and y.
  public let cornerPoints: [CGPoint]
  /// The input's dimensions after applying its orientation, in pixels.
  public let imageSize: CGSize
  /// Vision's confidence in this observation, between zero and one.
  public let confidence: Float

  init(observation: VNBarcodeObservation, imageSize: CGSize) {
    self.format = observation.symbology
    self.rawValue = observation.payloadStringValue
    if #available(iOS 17.0, *) {
      self.payloadData = observation.payloadData
    } else {
      self.payloadData = nil
    }
    self.imageSize = imageSize
    self.confidence = observation.confidence
    let box = observation.boundingBox
    self.boundingBox = CGRect(
      x: box.minX * imageSize.width,
      y: (1 - box.maxY) * imageSize.height,
      width: box.width * imageSize.width,
      height: box.height * imageSize.height)
    self.cornerPoints = [observation.topLeft, observation.topRight, observation.bottomRight, observation.bottomLeft].map {
      CGPoint(x: $0.x * imageSize.width, y: (1 - $0.y) * imageSize.height)
    }
  }
}
