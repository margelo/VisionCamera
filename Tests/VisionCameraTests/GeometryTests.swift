import AVFoundation
import CoreGraphics
import CoreVideo
import UIKit
import XCTest

@testable import VisionCamera

final class GeometryTests: XCTestCase {
  func testOrientationNormalizesDegreesAndRoundTripsNativeOrientations() throws {
    for orientation in CameraOrientation.allCases {
      for revolutions in -3...3 {
        XCTAssertEqual(CameraOrientation(degrees: orientation.degrees + revolutions * 360), orientation)
      }
      XCTAssertEqual(CameraOrientation(avOrientation: orientation.toAVCaptureVideoOrientation()), orientation)
      for isMirrored in [false, true] {
        let imageOrientation = orientation.toUIImageOrientation(isMirrored: isMirrored)
        XCTAssertEqual(CameraOrientation(uiOrientation: imageOrientation), orientation)
        XCTAssertEqual(imageOrientation.isMirrored, isMirrored)
        let exifOrientation = orientation.toCGOrientation(isMirrored: isMirrored)
        XCTAssertEqual(try UIImage.Orientation(fromExif: exifOrientation.rawValue), imageOrientation)
      }
      for relativeOrientation in CameraOrientation.allCases {
        XCTAssertEqual(orientation.relativeTo(relativeOrientation).rotatedBy(relativeOrientation), orientation)
      }
    }
    XCTAssertEqual(CameraOrientation(degrees: 44), .up)
    XCTAssertEqual(CameraOrientation(degrees: 45), .right)
    XCTAssertEqual(CameraOrientation(degrees: 134), .right)
    XCTAssertEqual(CameraOrientation(degrees: 135), .down)
    XCTAssertEqual(CameraOrientation(degrees: 224), .down)
    XCTAssertEqual(CameraOrientation(degrees: 225), .left)
    XCTAssertEqual(CameraOrientation(degrees: 314), .left)
    XCTAssertEqual(CameraOrientation(degrees: 315), .up)
  }

  func testFrameCoordinatesRoundTripForEveryRotationAndMirroringState() throws {
    let pixelBuffer = try makePixelBuffer()
    let points = [
      CGPoint(x: 0, y: 0),
      CGPoint(x: 640, y: 0),
      CGPoint(x: 0, y: 480),
      CGPoint(x: 640, y: 480),
      CGPoint(x: 320, y: 240),
      CGPoint(x: 73.5, y: 298.25),
    ]
    for orientation in CameraOrientation.allCases {
      for isMirrored in [false, true] {
        let frameToCamera = FrameCoordinateSystemConverter.getFrameToCameraMatrix(
          pixelBuffer: pixelBuffer, orientation: orientation, isMirrored: isMirrored
        )
        let cameraToFrame = FrameCoordinateSystemConverter.getCameraToFrameMatrix(
          pixelBuffer: pixelBuffer, orientation: orientation, isMirrored: isMirrored
        )
        for point in points {
          let cameraPoint = point.applying(frameToCamera)
          XCTAssertGreaterThanOrEqual(cameraPoint.x, -0.000001)
          XCTAssertLessThanOrEqual(cameraPoint.x, 1.000001)
          XCTAssertGreaterThanOrEqual(cameraPoint.y, -0.000001)
          XCTAssertLessThanOrEqual(cameraPoint.y, 1.000001)
          let restoredPoint = cameraPoint.applying(cameraToFrame)
          XCTAssertEqual(restoredPoint.x, point.x, accuracy: 0.000001)
          XCTAssertEqual(restoredPoint.y, point.y, accuracy: 0.000001)
        }
        let center = CGPoint(x: 320, y: 240).applying(frameToCamera)
        XCTAssertEqual(center.x, 0.5, accuracy: 0.000001)
        XCTAssertEqual(center.y, 0.5, accuracy: 0.000001)
      }
    }
  }

  func testFrameCoordinatesApplyCameraRotationAndMirroring() throws {
    let pixelBuffer = try makePixelBuffer()
    let point = CGPoint(x: 160, y: 360)
    let expectedPoints: [(CameraOrientation, CGPoint)] = [
      (.up, CGPoint(x: 0.25, y: 0.75)),
      (.right, CGPoint(x: 0.75, y: 0.75)),
      (.down, CGPoint(x: 0.75, y: 0.25)),
      (.left, CGPoint(x: 0.25, y: 0.25)),
    ]
    for (orientation, expected) in expectedPoints {
      let transform = FrameCoordinateSystemConverter.getFrameToCameraMatrix(
        pixelBuffer: pixelBuffer, orientation: orientation, isMirrored: false
      )
      let result = point.applying(transform)
      XCTAssertEqual(result.x, expected.x, accuracy: 0.000001)
      XCTAssertEqual(result.y, expected.y, accuracy: 0.000001)
    }
    let mirroredTransform = FrameCoordinateSystemConverter.getFrameToCameraMatrix(
      pixelBuffer: pixelBuffer, orientation: .up, isMirrored: true
    )
    let mirroredPoint = point.applying(mirroredTransform)
    XCTAssertEqual(mirroredPoint.x, 0.75, accuracy: 0.000001)
    XCTAssertEqual(mirroredPoint.y, 0.75, accuracy: 0.000001)
  }

  func testGeometryConversionsPreserveFractionalCoordinates() {
    let cgPoint = CGPoint(x: -5.5, y: 27.25)
    XCTAssertEqual(Point(cgPoint).toCGPoint(), cgPoint)
    XCTAssertEqual(Size(CGSize(width: 1920, height: 1080)), Size(width: 1920, height: 1080))
    XCTAssertEqual(
      BoundingBox(CGRect(x: 0.125, y: 0.25, width: 0.5, height: 0.75)),
      BoundingBox(x: 0.125, y: 0.25, width: 0.5, height: 0.75)
    )
  }

  private func makePixelBuffer() throws -> CVPixelBuffer {
    var pixelBuffer: CVPixelBuffer?
    let status = CVPixelBufferCreate(kCFAllocatorDefault, 640, 480, kCVPixelFormatType_32BGRA, nil, &pixelBuffer)
    XCTAssertEqual(status, kCVReturnSuccess)
    return try XCTUnwrap(pixelBuffer)
  }
}
