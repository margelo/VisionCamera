import ImageIO
import UIKit
import XCTest

@testable import VisionCameraBarcodeScanner

@available(iOS 16.0, *)
final class BarcodeUIImageGeometryTests: XCTestCase {
  func testUIKitOrientationMapsEveryEXIFRotationAndMirrorVariant() throws {
    let cases: [(UIImage.Orientation, CGImagePropertyOrientation)] = [
      (.up, .up), (.upMirrored, .upMirrored), (.down, .down), (.downMirrored, .downMirrored),
      (.left, .left), (.leftMirrored, .leftMirrored), (.right, .right), (.rightMirrored, .rightMirrored),
    ]
    for (input, expected) in cases {
      XCTAssertEqual(try BarcodeImageGeometry.orientation(from: input), expected)
    }
  }
}
