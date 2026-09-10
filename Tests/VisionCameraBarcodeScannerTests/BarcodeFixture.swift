import CoreImage
import CoreVideo
import ImageIO
import Vision
import XCTest

#if canImport(UIKit)
  import UIKit
#endif

struct BarcodeFixture {
  let image: CGImage
  let bounds: CGRect
  let value: String
  let format: VNBarcodeSymbology

  static func generated(filter name: String = "CIQRCodeGenerator", value: String = "VisionCamera barcode fixture", format: VNBarcodeSymbology = .qr) throws
    -> BarcodeFixture
  {
    let filter = try XCTUnwrap(CIFilter(name: name))
    filter.setValue(Data(value.utf8), forKey: "inputMessage")
    let code = try XCTUnwrap(filter.outputImage).transformed(by: CGAffineTransform(scaleX: 6, y: 6))
    let canvas = CGRect(x: 0, y: 0, width: max(640, code.extent.width + 200), height: max(480, code.extent.height + 180))
    let placed = code.transformed(by: CGAffineTransform(translationX: 60 - code.extent.minX, y: 40 - code.extent.minY))
    let background = CIImage(color: CIColor.white).cropped(to: canvas)
    let context = CIContext()
    let image = try XCTUnwrap(context.createCGImage(placed.composited(over: background), from: canvas))
    #if canImport(UIKit)
      XCTContext.runActivity(named: "Generated \(format.rawValue) fixture") { activity in
        activity.add(XCTAttachment(image: UIImage(cgImage: image)))
      }
    #endif
    // CIQRCodeGenerator includes one module of white border inside its output extent.
    let generatedBounds = CGRect(x: 60, y: canvas.height - 40 - code.extent.height, width: code.extent.width, height: code.extent.height)
    let inkBounds = name == "CIQRCodeGenerator" ? generatedBounds.insetBy(dx: 6, dy: 6) : generatedBounds
    return BarcodeFixture(
      image: image,
      bounds: inkBounds,
      value: value,
      format: format)
  }

  // EAN-13 encoding of the UPC-A example 036000291452 with the required leading zero.
  static func upcA() throws -> BarcodeFixture {
    let value = "0036000291452"
    let left = ["0001101", "0011001", "0010011", "0111101", "0100011", "0110001", "0101111", "0111011", "0110111", "0001011"]
    let right = ["1110010", "1100110", "1101100", "1000010", "1011100", "1001110", "1010000", "1000100", "1001000", "1110100"]
    let digits = value.compactMap(\.wholeNumberValue)
    let bits = "101" + digits[1...6].map { left[$0] }.joined() + "01010" + digits[7...12].map { right[$0] }.joined() + "101"
    let context = try bitmapContext(width: 640, height: 480)
    context.setFillColor(CGColor(gray: 1, alpha: 1))
    context.fill(CGRect(x: 0, y: 0, width: 640, height: 480))
    context.setFillColor(CGColor(gray: 0, alpha: 1))
    for (index, bit) in bits.enumerated() where bit == "1" {
      context.fill(CGRect(x: 60 + index * 4, y: 40, width: 4, height: 180))
    }
    return BarcodeFixture(
      image: try XCTUnwrap(context.makeImage()), bounds: CGRect(x: 60, y: 260, width: bits.count * 4, height: 180), value: value, format: .ean13)
  }

  func pixelBuffer(released: XCTestExpectation? = nil) throws -> CVPixelBuffer {
    var buffer: CVPixelBuffer?
    let status: CVReturn
    if let released {
      let bytes = UnsafeMutableRawPointer.allocate(byteCount: image.width * image.height * 4, alignment: 64)
      let releaseContext = Unmanaged.passRetained(released).toOpaque()
      status = CVPixelBufferCreateWithBytes(
        kCFAllocatorDefault, image.width, image.height, kCVPixelFormatType_32BGRA, bytes, image.width * 4,
        { context, bytes in
          UnsafeMutableRawPointer(mutating: bytes)?.deallocate()
          if let context { Unmanaged<XCTestExpectation>.fromOpaque(context).takeRetainedValue().fulfill() }
        }, releaseContext, nil, &buffer)
      if status != kCVReturnSuccess {
        bytes.deallocate()
        Unmanaged<XCTestExpectation>.fromOpaque(releaseContext).release()
      }
    } else {
      status = CVPixelBufferCreate(
        kCFAllocatorDefault, image.width, image.height, kCVPixelFormatType_32BGRA,
        [kCVPixelBufferCGImageCompatibilityKey: true, kCVPixelBufferCGBitmapContextCompatibilityKey: true] as CFDictionary,
        &buffer)
    }
    XCTAssertEqual(status, kCVReturnSuccess)
    let result = try XCTUnwrap(buffer)
    XCTAssertEqual(CVPixelBufferLockBaseAddress(result, []), kCVReturnSuccess)
    defer { CVPixelBufferUnlockBaseAddress(result, []) }
    let context = try XCTUnwrap(
      CGContext(
        data: CVPixelBufferGetBaseAddress(result), width: image.width, height: image.height, bitsPerComponent: 8,
        bytesPerRow: CVPixelBufferGetBytesPerRow(result), space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGBitmapInfo.byteOrder32Little.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue))
    // Match the image's top-to-bottom memory layout.
    context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
    return result
  }

  func orientedBounds(_ orientation: CGImagePropertyOrientation) -> CGRect {
    let width = CGFloat(image.width)
    let height = CGFloat(image.height)
    switch orientation {
    case .up: return bounds
    case .upMirrored: return CGRect(x: width - bounds.maxX, y: bounds.minY, width: bounds.width, height: bounds.height)
    case .down: return CGRect(x: width - bounds.maxX, y: height - bounds.maxY, width: bounds.width, height: bounds.height)
    case .downMirrored: return CGRect(x: bounds.minX, y: height - bounds.maxY, width: bounds.width, height: bounds.height)
    case .leftMirrored: return CGRect(x: bounds.minY, y: bounds.minX, width: bounds.height, height: bounds.width)
    case .right: return CGRect(x: height - bounds.maxY, y: bounds.minX, width: bounds.height, height: bounds.width)
    case .rightMirrored: return CGRect(x: height - bounds.maxY, y: width - bounds.maxX, width: bounds.height, height: bounds.width)
    case .left: return CGRect(x: bounds.minY, y: width - bounds.maxX, width: bounds.height, height: bounds.width)
    }
  }

  private static func bitmapContext(width: Int, height: Int) throws -> CGContext {
    return try XCTUnwrap(
      CGContext(
        data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
        space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
  }
}
