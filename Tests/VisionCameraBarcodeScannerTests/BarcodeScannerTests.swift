import AVFoundation
import CoreImage
import ImageIO
import Vision
import XCTest

@testable import VisionCameraBarcodeScanner

@available(iOS 16.0, *)
final class BarcodeScannerTests: XCTestCase {
  func testDetectsGeneratedQRPDF417AztecAndCode128Fixtures() throws {
    try BarcodeRuntimeSupport.requireDetection()
    let fixtures: [(String, VNBarcodeSymbology)] = [
      ("CIQRCodeGenerator", .qr),
      ("CIPDF417BarcodeGenerator", .pdf417),
      ("CIAztecCodeGenerator", .aztec),
      ("CICode128BarcodeGenerator", .code128),
    ]
    for (filter, format) in fixtures {
      let fixture = try BarcodeFixture.generated(filter: filter, format: format)
      let scanner = try BarcodeScanner(options: .init(symbologies: [format]))
      let barcodes = try scanner.scan(image: fixture.image)
      XCTAssertEqual(barcodes.count, 1, format.rawValue)
      let barcode = try XCTUnwrap(barcodes.first)
      XCTAssertEqual(barcode.format, format)
      XCTAssertEqual(barcode.rawValue, fixture.value)
      if #available(iOS 17.0, *) {
        let reference = VNDetectBarcodesRequest()
        reference.revision = VNDetectBarcodesRequestRevision4
        reference.symbologies = [format]
        try BarcodeComputeConfiguration(request: reference).apply(to: reference)
        try VNImageRequestHandler(cgImage: fixture.image).perform([reference])
        XCTAssertEqual(barcode.payloadData, try XCTUnwrap(reference.results?.first).payloadData)
      }
      XCTAssertEqual(barcode.imageSize, CGSize(width: fixture.image.width, height: fixture.image.height))
      XCTAssertEqual(barcode.cornerPoints.count, 4)
      XCTAssertGreaterThan(barcode.boundingBox.width, 0)
      XCTAssertGreaterThan(barcode.boundingBox.height, 0)
    }
  }

  func testUPCAReportsEAN13WithLeadingZero() throws {
    try BarcodeRuntimeSupport.requireDetection()
    let fixture = try BarcodeFixture.upcA()
    let barcode = try XCTUnwrap(BarcodeScanner(options: .init(symbologies: [.ean13])).scan(image: fixture.image).first)
    XCTAssertEqual(barcode.format, .ean13)
    XCTAssertEqual(barcode.rawValue, "0036000291452")
  }

  func testIOS16DetectorRevisionSupportsOriginalFormatsAndDecodesFixtures() throws {
    try BarcodeRuntimeSupport.requireDetection(revision: 3)
    // Exercise the iOS 16 request revision even when the test host runs a newer OS.
    let request = VNDetectBarcodesRequest()
    request.revision = VNDetectBarcodesRequestRevision3
    try BarcodeComputeConfiguration(request: request).apply(to: request)
    let supported = try request.supportedSymbologies()
    let originalFormats: [VNBarcodeSymbology] = [.code128, .code39, .code93, .codabar, .dataMatrix, .ean13, .ean8, .i2of5, .qr, .upce, .pdf417, .aztec]
    for format in originalFormats { XCTAssertTrue(supported.contains(format), format.rawValue) }
    let fixtures = try [
      BarcodeFixture.generated(),
      BarcodeFixture.generated(filter: "CIPDF417BarcodeGenerator", format: .pdf417),
      BarcodeFixture.generated(filter: "CIAztecCodeGenerator", format: .aztec),
      BarcodeFixture.generated(filter: "CICode128BarcodeGenerator", format: .code128),
      BarcodeFixture.upcA(),
    ]
    for fixture in fixtures {
      request.symbologies = [fixture.format]
      try VNImageRequestHandler(cgImage: fixture.image).perform([request])
      let observation = try XCTUnwrap(request.results?.first)
      XCTAssertEqual(observation.payloadStringValue, fixture.value)
      XCTAssertEqual(observation.symbology, fixture.format)
    }
  }

  func testAllEightEXIFOrientationsUseOrientedTopLeftPixelCoordinates() throws {
    try BarcodeRuntimeSupport.requireDetection()
    let fixture = try BarcodeFixture.generated()
    let scanner = try BarcodeScanner(options: .init(symbologies: [.qr]))
    let orientations: [CGImagePropertyOrientation] = [.up, .upMirrored, .down, .downMirrored, .leftMirrored, .right, .rightMirrored, .left]
    for orientation in orientations {
      let barcode = try XCTUnwrap(scanner.scan(image: fixture.image, orientation: orientation).first)
      XCTAssertEqual(barcode.rawValue, fixture.value)
      assertBounds(barcode.boundingBox, equals: fixture.orientedBounds(orientation))
      let cornerBounds = barcode.cornerPoints.reduce(CGRect.null) { $0.union(CGRect(origin: $1, size: .zero)) }
      assertBounds(cornerBounds, equals: barcode.boundingBox, accuracy: 1)
      if [.left, .leftMirrored, .right, .rightMirrored].contains(orientation) {
        XCTAssertEqual(barcode.imageSize, CGSize(width: fixture.image.height, height: fixture.image.width))
      } else {
        XCTAssertEqual(barcode.imageSize, CGSize(width: fixture.image.width, height: fixture.image.height))
      }
    }
  }

  func testScannerReleasesPixelBufferWhileKeepingResultsUsable() throws {
    try BarcodeRuntimeSupport.requireDetection()
    let released = expectation(description: "Scanner released the input pixels")
    let fixture = try BarcodeFixture.generated()
    let scanner = try BarcodeScanner(options: .init(symbologies: [.qr]))
    let barcode: Barcode = try autoreleasepool {
      let buffer = try fixture.pixelBuffer(released: released)
      return try XCTUnwrap(scanner.scan(pixelBuffer: buffer).first)
    }
    wait(for: [released], timeout: 1)
    XCTAssertEqual(barcode.rawValue, fixture.value)
    assertBounds(barcode.boundingBox, equals: fixture.bounds)
    scanner.cancel()
    XCTAssertEqual(try scanner.scan(image: fixture.image).first?.rawValue, fixture.value)
  }

  func testScannerDoesNotRetainInputWhenResultsAreDiscarded() throws {
    let released = expectation(description: "Scanner released pixels after processing returned")
    let fixture = try BarcodeFixture.generated()
    let scanner = try BarcodeScanner(options: .init(symbologies: [.qr]))
    try autoreleasepool {
      let buffer = try fixture.pixelBuffer(released: released)
      _ = try scanner.scan(pixelBuffer: buffer)
    }
    wait(for: [released], timeout: 1)
  }

  func testSymbologyFilterDoesNotReturnQRCodeWhenOnlyCode128IsRequested() throws {
    try BarcodeRuntimeSupport.requireDetection()
    let fixture = try BarcodeFixture.generated()
    let scanner = try BarcodeScanner(options: .init(symbologies: [.code128]))
    XCTAssertTrue(try scanner.scan(image: fixture.image).isEmpty)
  }

  func testBlankInputAndInvalidImage() throws {
    let image = CIImage(color: .white).cropped(to: CGRect(x: 0, y: 0, width: 640, height: 480))
    let scanner = try BarcodeScanner()
    XCTAssertTrue(try scanner.scan(image: image).isEmpty)
    XCTAssertThrowsError(try scanner.scan(image: CIImage(color: .white)))
  }

  func testRequestedFormatsAreSupportedAndInvalidSelectionsThrow() throws {
    let formats: [VNBarcodeSymbology] = [.code128, .code39, .code93, .codabar, .dataMatrix, .ean13, .ean8, .i2of5, .qr, .upce, .pdf417, .aztec]
    let supported = try BarcodeScanner.supportedSymbologies()
    for format in formats { XCTAssertTrue(supported.contains(format), format.rawValue) }
    XCTAssertNoThrow(try BarcodeScanner(options: .init(symbologies: formats)))
    XCTAssertThrowsError(try BarcodeScanner(options: .init(symbologies: []))) { error in
      guard case BarcodeScannerError.emptySymbologies = error else { return XCTFail("Unexpected error: \(error)") }
    }
    let unknown = VNBarcodeSymbology(rawValue: "VisionCameraUnsupportedTestFormat")
    XCTAssertThrowsError(try BarcodeScanner(options: .init(symbologies: [.qr, unknown]))) { error in
      guard case BarcodeScannerError.unsupportedSymbologies(let values) = error else { return XCTFail("Unexpected error: \(error)") }
      XCTAssertEqual(values, [unknown])
    }
  }

  private func assertBounds(_ actual: CGRect, equals expected: CGRect, accuracy: CGFloat = 8, file: StaticString = #filePath, line: UInt = #line) {
    XCTAssertEqual(actual.minX, expected.minX, accuracy: accuracy, file: file, line: line)
    XCTAssertEqual(actual.minY, expected.minY, accuracy: accuracy, file: file, line: line)
    XCTAssertEqual(actual.width, expected.width, accuracy: accuracy, file: file, line: line)
    XCTAssertEqual(actual.height, expected.height, accuracy: accuracy, file: file, line: line)
  }
}
