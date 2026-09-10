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
        XCTAssertEqual(UIImage.Orientation(exifValue: exifOrientation.rawValue), imageOrientation)
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
        let frame = try makeFrame(pixelBuffer: pixelBuffer, orientation: orientation, isMirrored: isMirrored)
        for point in points {
          let cameraPoint = try frame.cameraPoint(from: point)
          XCTAssertGreaterThanOrEqual(cameraPoint.x, -0.000001)
          XCTAssertLessThanOrEqual(cameraPoint.x, 1.000001)
          XCTAssertGreaterThanOrEqual(cameraPoint.y, -0.000001)
          XCTAssertLessThanOrEqual(cameraPoint.y, 1.000001)
          let restoredPoint = try frame.point(fromCameraPoint: cameraPoint)
          XCTAssertEqual(restoredPoint.x, point.x, accuracy: 0.000001)
          XCTAssertEqual(restoredPoint.y, point.y, accuracy: 0.000001)
        }
        let center = try frame.cameraPoint(from: CGPoint(x: 320, y: 240))
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
      let frame = try makeFrame(pixelBuffer: pixelBuffer, orientation: orientation, isMirrored: false)
      let result = try frame.cameraPoint(from: point)
      XCTAssertEqual(result.x, expected.x, accuracy: 0.000001)
      XCTAssertEqual(result.y, expected.y, accuracy: 0.000001)
    }
    let mirroredFrame = try makeFrame(pixelBuffer: pixelBuffer, orientation: .up, isMirrored: true)
    let mirroredPoint = try mirroredFrame.cameraPoint(from: point)
    XCTAssertEqual(mirroredPoint.x, 0.75, accuracy: 0.000001)
    XCTAssertEqual(mirroredPoint.y, 0.75, accuracy: 0.000001)
  }

  private func makeFrame(pixelBuffer: CVPixelBuffer, orientation: CameraOrientation, isMirrored: Bool) throws -> Frame {
    let format = try CMFormatDescription(imageBuffer: pixelBuffer)
    let timing = CMSampleTimingInfo(duration: .invalid, presentationTimeStamp: .zero, decodeTimeStamp: .invalid)
    let sample = try CMSampleBuffer(imageBuffer: pixelBuffer, formatDescription: format, sampleTiming: timing)
    return Frame(
      sampleBuffer: sample,
      metadata: MediaSampleMetadata(
        timestamp: .zero, orientation: orientation, isMirrored: isMirrored))
  }

  private func makePixelBuffer() throws -> CVPixelBuffer {
    var pixelBuffer: CVPixelBuffer?
    let status = CVPixelBufferCreate(kCFAllocatorDefault, 640, 480, kCVPixelFormatType_32BGRA, nil, &pixelBuffer)
    XCTAssertEqual(status, kCVReturnSuccess)
    return try XCTUnwrap(pixelBuffer)
  }
}
