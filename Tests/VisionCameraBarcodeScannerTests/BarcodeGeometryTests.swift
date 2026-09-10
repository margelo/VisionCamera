import CoreGraphics
import ImageIO
import Vision
import XCTest

@testable import VisionCameraBarcodeScanner

@available(iOS 16.0, *)
final class BarcodeGeometryTests: XCTestCase {
  func testNativeObservationConvertsToTopLeftPixelsAndPreservesOutOfBoundsCorners() {
    let observation: VNBarcodeObservation
    if #available(iOS 17.0, *) {
      observation = VNBarcodeObservation(
        requestRevision: 3,
        topLeft: CGPoint(x: -0.1, y: 1.2), topRight: CGPoint(x: 0.8, y: 1.1),
        bottomRight: CGPoint(x: 0.9, y: 0.3), bottomLeft: CGPoint(x: 0, y: 0.4))
    } else {
      observation = VNBarcodeObservation(
        requestRevision: 3,
        topLeft: CGPoint(x: -0.1, y: 1.2), bottomLeft: CGPoint(x: 0, y: 0.4),
        bottomRight: CGPoint(x: 0.9, y: 0.3), topRight: CGPoint(x: 0.8, y: 1.1))
    }
    let barcode = Barcode(observation: observation, imageSize: CGSize(width: 200, height: 100))
    XCTAssertEqual(barcode.boundingBox.minX, -20, accuracy: 0.001)
    XCTAssertEqual(barcode.boundingBox.minY, -20, accuracy: 0.001)
    XCTAssertEqual(barcode.boundingBox.width, 200, accuracy: 0.001)
    XCTAssertEqual(barcode.boundingBox.height, 90, accuracy: 0.001)
    let expected = [CGPoint(x: -20, y: -20), CGPoint(x: 160, y: -10), CGPoint(x: 180, y: 70), CGPoint(x: 0, y: 60)]
    for (actual, expected) in zip(barcode.cornerPoints, expected) {
      XCTAssertEqual(actual.x, expected.x, accuracy: 0.001)
      XCTAssertEqual(actual.y, expected.y, accuracy: 0.001)
    }
  }

  func testOrientedSizeSwapsAxesOnlyForQuarterTurns() {
    let size = CGSize(width: 640, height: 480)
    for orientation: CGImagePropertyOrientation in [.up, .upMirrored, .down, .downMirrored] {
      XCTAssertEqual(BarcodeImageGeometry.orientedSize(size, orientation: orientation), size)
    }
    for orientation: CGImagePropertyOrientation in [.left, .leftMirrored, .right, .rightMirrored] {
      XCTAssertEqual(BarcodeImageGeometry.orientedSize(size, orientation: orientation), CGSize(width: 480, height: 640))
    }
  }
}
