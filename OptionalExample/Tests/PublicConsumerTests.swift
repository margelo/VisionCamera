// Copyright © 2026 Marc Rousavy @ Margelo

import UIKit
import XCTest

#if USE_VISIONCAMERA
  import VisionCamera
#endif
#if USE_VISIONCAMERARESIZER
  import CoreVideo
  import Metal
  import VisionCameraResizer
#endif
#if USE_VISIONCAMERABARCODESCANNER
  import CoreImage
  import Vision
  import VisionCameraBarcodeScanner
#endif
#if USE_VISIONCAMERALOCATION
  import VisionCameraLocation
#endif

final class PublicConsumerTests: XCTestCase {
  #if USE_VISIONCAMERA
    @MainActor
    func testCoreConstructionDoesNotStartCapture() {
      let session = CameraSession()
      let preview = PreviewView()
      preview.output = PreviewOutput()
      XCTAssertFalse(session.isRunning)
      XCTAssertTrue(session.session.inputs.isEmpty)
      #if !USE_VISIONCAMERALOCATION
        XCTAssertNil(Bundle.main.object(forInfoDictionaryKey: "NSLocationWhenInUseUsageDescription"))
      #endif
    }
  #endif

  #if USE_VISIONCAMERARESIZER
    func testInstalledShaderAndOwnedOutput() throws {
      guard MTLCreateSystemDefaultDevice() != nil else { throw XCTSkip("Metal is unavailable on this destination.") }
      let result = try autoreleasepool {
        let attributes: [CFString: Any] = [kCVPixelBufferIOSurfacePropertiesKey: [:], kCVPixelBufferMetalCompatibilityKey: true]
        var source: CVPixelBuffer?
        XCTAssertEqual(
          CVPixelBufferCreate(nil, 4, 4, kCVPixelFormatType_420YpCbCr8BiPlanarFullRange, attributes as CFDictionary, &source),
          kCVReturnSuccess)
        let buffer = try XCTUnwrap(source)
        XCTAssertEqual(CVPixelBufferLockBaseAddress(buffer, []), kCVReturnSuccess)
        for plane in 0..<2 {
          let base = try XCTUnwrap(CVPixelBufferGetBaseAddressOfPlane(buffer, plane))
          let count = CVPixelBufferGetBytesPerRowOfPlane(buffer, plane) * CVPixelBufferGetHeightOfPlane(buffer, plane)
          base.initializeMemory(as: UInt8.self, repeating: 128, count: count)
        }
        CVPixelBufferUnlockBaseAddress(buffer, [])
        let resizer = try GPUResizer(options: .init(width: 2, height: 2))
        return try resizer.resize(buffer)
      }
      XCTAssertEqual(result.byteCount, 12)
      result.withUnsafeBytes { bytes in
        XCTAssertEqual(bytes.count, 12)
        for value in bytes { XCTAssertEqual(Double(value), 128, accuracy: 2) }
      }
    }
  #endif

  #if USE_VISIONCAMERABARCODESCANNER
    func testInstalledScannerDetectsQRPayload() throws {
      try BarcodeRuntimeSupport.requireDetection()
      let payload = "VisionCamera public consumer"
      let generator = try XCTUnwrap(CIFilter(name: "CIQRCodeGenerator"))
      generator.setValue(Data(payload.utf8), forKey: "inputMessage")
      generator.setValue("M", forKey: "inputCorrectionLevel")
      let code = try XCTUnwrap(generator.outputImage).transformed(by: CGAffineTransform(scaleX: 8, y: 8))
      let background = CIImage(color: .white).cropped(to: code.extent.insetBy(dx: -40, dy: -40))
      let fixture = code.composited(over: background)
      let image = try XCTUnwrap(CIContext().createCGImage(fixture, from: fixture.extent))
      let scanner = try BarcodeScanner(options: .init(symbologies: [.qr]))
      let barcode = try XCTUnwrap(scanner.scan(image: image).first)
      XCTAssertEqual(barcode.rawValue, payload)
      XCTAssertEqual(barcode.format, .qr)
      XCTAssertEqual(barcode.imageSize, CGSize(width: image.width, height: image.height))
      XCTAssertEqual(barcode.cornerPoints.count, 4)
      XCTAssertGreaterThan(barcode.boundingBox.width, 0)
      XCTAssertGreaterThan(barcode.boundingBox.height, 0)
    }

  #endif

  #if USE_VISIONCAMERALOCATION
    @MainActor
    func testLocationConstructionDoesNotRequestUpdates() throws {
      let manager = try LocationManager()
      XCTAssertFalse(manager.isUpdating)
      manager.stopUpdating()
      XCTAssertFalse(manager.isUpdating)
      // Authorization and GPS are controlled by the OS; this test makes no permission request.
      #if !USE_VISIONCAMERA
        XCTAssertNil(Bundle.main.object(forInfoDictionaryKey: "NSCameraUsageDescription"))
        XCTAssertNil(Bundle.main.object(forInfoDictionaryKey: "NSMicrophoneUsageDescription"))
      #endif
    }
  #endif
}
