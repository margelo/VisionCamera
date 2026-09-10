import AVFoundation
import CoreVideo
import Metal
import VisionCamera
import VisionCameraResizer
import XCTest

enum ResizerTestImage {
  static func requireMetal() throws {
    guard MTLCreateSystemDefaultDevice() != nil else { throw XCTSkip("This destination has no Metal device.") }
  }

  static func make(width: Int = 4, height: Int = 2, luma: [UInt8], cb: UInt8 = 128, cr: UInt8 = 128) throws -> CVPixelBuffer {
    let attributes: [CFString: Any] = [kCVPixelBufferMetalCompatibilityKey: true, kCVPixelBufferIOSurfacePropertiesKey: [:]]
    var buffer: CVPixelBuffer?
    let status = CVPixelBufferCreate(
      kCFAllocatorDefault, width, height, kCVPixelFormatType_420YpCbCr8BiPlanarFullRange, attributes as CFDictionary, &buffer)
    XCTAssertEqual(status, kCVReturnSuccess)
    let image = try XCTUnwrap(buffer)
    XCTAssertEqual(luma.count, width * height)
    XCTAssertEqual(CVPixelBufferLockBaseAddress(image, []), kCVReturnSuccess)
    defer { CVPixelBufferUnlockBaseAddress(image, []) }
    let yBytes = try XCTUnwrap(CVPixelBufferGetBaseAddressOfPlane(image, 0)).assumingMemoryBound(to: UInt8.self)
    let uvBytes = try XCTUnwrap(CVPixelBufferGetBaseAddressOfPlane(image, 1)).assumingMemoryBound(to: UInt8.self)
    for y in 0..<height {
      for x in 0..<width {
        yBytes[y * CVPixelBufferGetBytesPerRowOfPlane(image, 0) + x] = luma[y * width + x]
      }
    }
    for y in 0..<CVPixelBufferGetHeightOfPlane(image, 1) {
      for x in 0..<CVPixelBufferGetWidthOfPlane(image, 1) {
        uvBytes[y * CVPixelBufferGetBytesPerRowOfPlane(image, 1) + x * 2] = cb
        uvBytes[y * CVPixelBufferGetBytesPerRowOfPlane(image, 1) + x * 2 + 1] = cr
      }
    }
    return image
  }

  static func frame(_ image: CVPixelBuffer, orientation: CameraOrientation = .up, isMirrored: Bool = false) throws -> Frame {
    let format = try CMFormatDescription(imageBuffer: image)
    let timing = CMSampleTimingInfo(duration: .invalid, presentationTimeStamp: .zero, decodeTimeStamp: .invalid)
    let sample = try CMSampleBuffer(imageBuffer: image, formatDescription: format, sampleTiming: timing)
    return Frame(sampleBuffer: sample, metadata: MediaSampleMetadata(timestamp: .zero, orientation: orientation, isMirrored: isMirrored))
  }

  static func values(_ result: GPUResizeResult) -> [Double] {
    return result.withUnsafeBytes { bytes in
      switch result.dataType {
      case .uint8: return bytes.bindMemory(to: UInt8.self).map(Double.init)
      case .int8: return bytes.bindMemory(to: Int8.self).map(Double.init)
      case .float16: return bytes.bindMemory(to: UInt16.self).map { Double(Float16(bitPattern: $0)) }
      case .float32: return bytes.bindMemory(to: Float.self).map(Double.init)
      }
    }
  }

  static func assertLuma(_ result: GPUResizeResult, _ expected: [Double], file: StaticString = #filePath, line: UInt = #line) {
    let actual = values(result)
    XCTAssertEqual(actual.count, expected.count * 3, file: file, line: line)
    for (index, luma) in expected.enumerated() {
      for channel in 0..<3 {
        XCTAssertEqual(actual[index * 3 + channel], luma, accuracy: 1.5, "Pixel \(index), channel \(channel)", file: file, line: line)
      }
    }
  }
}
