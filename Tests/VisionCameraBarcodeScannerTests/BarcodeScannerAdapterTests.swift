import AVFoundation
import CoreImage
import CoreMedia
import UIKit
import VisionCamera
import XCTest

@testable import VisionCameraBarcodeScanner

@available(iOS 16.0, *)
final class BarcodeScannerAdapterTests: XCTestCase {
  func testUIImageUsesPixelDimensionsAndOrientation() throws {
    try BarcodeRuntimeSupport.requireDetection()
    let fixture = try BarcodeFixture.generated()
    let image = UIImage(cgImage: fixture.image, scale: 3, orientation: .right)
    let scanner = try BarcodeScanner(options: .init(symbologies: [.qr]))
    let barcode = try XCTUnwrap(scanner.scan(image: image).first)
    XCTAssertEqual(barcode.imageSize, CGSize(width: fixture.image.height, height: fixture.image.width))
    assertBounds(barcode.boundingBox, equals: fixture.orientedBounds(.right))
  }

  func testCoreImageBackedUIImageUsesItsFiniteExtentAndOrientation() throws {
    try BarcodeRuntimeSupport.requireDetection()
    let fixture = try BarcodeFixture.generated()
    let ciImage = CIImage(cgImage: fixture.image).transformed(by: CGAffineTransform(translationX: -50, y: 70))
    let image = UIImage(ciImage: ciImage, scale: 2, orientation: .downMirrored)
    let scanner = try BarcodeScanner(options: .init(symbologies: [.qr]))
    let barcode = try XCTUnwrap(scanner.scan(image: image).first)
    XCTAssertEqual(barcode.rawValue, fixture.value)
    XCTAssertEqual(barcode.imageSize, CGSize(width: fixture.image.width, height: fixture.image.height))
    assertBounds(barcode.boundingBox, equals: fixture.orientedBounds(.downMirrored))
  }

  func testFrameMetadataAndOwnedResultSurviveInvalidationAndNextScan() throws {
    try BarcodeRuntimeSupport.requireDetection()
    let fixture = try BarcodeFixture.generated(value: "WIFI:T:WPA;S:Test;P:example;;")
    let pixelBuffer = try fixture.pixelBuffer()
    var format: CMVideoFormatDescription?
    XCTAssertEqual(CMVideoFormatDescriptionCreateForImageBuffer(allocator: kCFAllocatorDefault, imageBuffer: pixelBuffer, formatDescriptionOut: &format), noErr)
    var timing = CMSampleTimingInfo(duration: .invalid, presentationTimeStamp: .zero, decodeTimeStamp: .invalid)
    var sample: CMSampleBuffer?
    XCTAssertEqual(
      CMSampleBufferCreateReadyWithImageBuffer(
        allocator: kCFAllocatorDefault, imageBuffer: pixelBuffer, formatDescription: try XCTUnwrap(format), sampleTiming: &timing, sampleBufferOut: &sample),
      noErr)
    let frame = Frame(sampleBuffer: try XCTUnwrap(sample), metadata: .init(timestamp: .zero, orientation: .right, isMirrored: true))
    let scanner = try BarcodeScanner(options: .init(symbologies: [.qr]))
    let barcode = try XCTUnwrap(scanner.scan(frame: frame).first)
    let expected = try XCTUnwrap(scanner.scan(pixelBuffer: pixelBuffer, orientation: .rightMirrored).first)
    XCTAssertEqual(barcode.rawValue, fixture.value)
    assertBounds(barcode.boundingBox, equals: expected.boundingBox, accuracy: 1)
    CMSampleBufferInvalidate(frame.sampleBuffer)
    XCTAssertThrowsError(try scanner.scan(frame: frame))
    _ = try scanner.scan(image: BarcodeFixture.generated(value: "another result").image)
    XCTAssertEqual(barcode.rawValue, fixture.value)
    if #available(iOS 17.0, *) {
      XCTAssertEqual(barcode.payloadData, expected.payloadData)
    } else {
      XCTAssertNil(barcode.payloadData)
    }
  }

  func testInvalidatedFrameFailsBeforeStartingInference() throws {
    let pixelBuffer = try BarcodeFixture.generated().pixelBuffer()
    let sample = try CMSampleBuffer(
      imageBuffer: pixelBuffer,
      formatDescription: CMFormatDescription(imageBuffer: pixelBuffer),
      sampleTiming: CMSampleTimingInfo(duration: .invalid, presentationTimeStamp: .zero, decodeTimeStamp: .invalid))
    let frame = Frame(sampleBuffer: sample, metadata: .init(timestamp: .zero, orientation: .up, isMirrored: false))
    CMSampleBufferInvalidate(sample)
    let scanner = try BarcodeScanner()
    XCTAssertThrowsError(try scanner.scan(frame: frame)) { error in
      guard case .invalidSampleBuffer? = error as? MediaError else {
        return XCTFail("Expected invalid sample validation before Vision inference")
      }
    }
  }

  func testUnsupportedUIImageThrowsWithoutStartingInference() throws {
    let scanner = try BarcodeScanner()
    XCTAssertThrowsError(try scanner.scan(image: UIImage()))
  }

  private func assertBounds(_ actual: CGRect, equals expected: CGRect, accuracy: CGFloat = 8, file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertEqual(actual.minX, expected.minX, accuracy: accuracy, file: file, line: line)
    XCTAssertEqual(actual.minY, expected.minY, accuracy: accuracy, file: file, line: line)
    XCTAssertEqual(actual.width, expected.width, accuracy: accuracy, file: file, line: line)
    XCTAssertEqual(actual.height, expected.height, accuracy: accuracy, file: file, line: line)
  }
}
