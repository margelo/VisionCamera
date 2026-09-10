import AVFoundation
import CoreVideo
import VisionCamera
import XCTest

final class BufferTests: XCTestCase {
  func testNativeBuffersRemainValidAfterFrameValueLeavesScope() throws {
    let retained = try autoreleasepool { () -> (CMSampleBuffer, CVPixelBuffer) in
      let frame = try makeFrame()
      return (frame.sampleBuffer, try XCTUnwrap(frame.pixelBuffer))
    }
    XCTAssertTrue(CMSampleBufferIsValid(retained.0))
    XCTAssertEqual(CVPixelBufferGetWidth(retained.1), 8)
  }

  func testCopiedFrameRetainsNativeMemoryUntilItsLastOwnerLeavesScope() throws {
    let released = expectation(description: "Last Frame copy released the pixel buffer")
    try autoreleasepool {
      var original: Frame? = try makeTrackedFrame(released: released)
      let copy = try XCTUnwrap(original)
      original = nil
      XCTAssertTrue(copy.isValid)
      XCTAssertEqual(try copy.withUnsafeBytes { $0.first }, 0x2A)
    }
    wait(for: [released], timeout: 1)
  }

  func testPackedBytesRemainAliveThroughoutScopeAndCopiedDataOutlivesTheFrame() throws {
    let released = expectation(description: "Native pixel memory was released")
    let data = try autoreleasepool { () throws -> Data in
      var frame: Frame? = try makeTrackedFrame(released: released)
      return try XCTUnwrap(frame).withUnsafeBytes { bytes in
        frame = nil
        XCTAssertEqual(bytes.count, 8 * 4 * 4)
        XCTAssertEqual(bytes.first, 0x2A)
        return Data(bytes)
      }
    }
    wait(for: [released], timeout: 1)
    XCTAssertEqual(data, Data(repeating: 0x2A, count: 8 * 4 * 4))
  }

  func testThrowingByteScopePropagatesTheErrorAndStillReleasesNativeMemory() throws {
    let released = expectation(description: "Native memory released after throwing access")
    let failure = NSError(domain: "BufferTests", code: 1)
    try autoreleasepool {
      let frame = try makeTrackedFrame(released: released)
      XCTAssertThrowsError(try frame.withUnsafeBytes { _ -> Void in throw failure }) { error in
        XCTAssertEqual(error as NSError, failure)
      }
      XCTAssertEqual(try frame.withUnsafeBytes { $0.count }, 8 * 4 * 4)
    }
    wait(for: [released], timeout: 1)
  }

  func testPlanarBoundsAndIndependentPlaneLifetime() throws {
    let planes = try autoreleasepool { () throws -> [FramePlane] in
      let frame = try makeFrame(pixelFormat: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
      let pixelBuffer = try XCTUnwrap(frame.pixelBuffer)
      for index in [-1, 2] {
        XCTAssertThrowsError(try FramePlane(pixelBuffer: pixelBuffer, index: index)) { error in
          guard case .invalidPlaneIndex(let invalidIndex, let planeCount)? = error as? MediaError else {
            return XCTFail("Expected a typed plane-index error")
          }
          XCTAssertEqual(invalidIndex, index)
          XCTAssertEqual(planeCount, 2)
        }
      }
      XCTAssertThrowsError(try frame.withUnsafeBytes { $0.count }) { error in
        guard case .nonPlanarPixelBufferRequired? = error as? MediaError else {
          return XCTFail("Packed byte access must reject planar buffers")
        }
      }
      return try frame.planes
    }
    XCTAssertEqual(planes.count, 2)
    XCTAssertEqual(planes[0].width, 8)
    XCTAssertEqual(planes[0].height, 4)
    XCTAssertEqual(planes[1].width, 4)
    XCTAssertEqual(planes[1].height, 2)
    for plane in planes {
      XCTAssertEqual(try plane.withUnsafeBytes { $0.count }, plane.byteCount)
      let failure = NSError(domain: "PlaneTests", code: plane.index)
      XCTAssertThrowsError(try plane.withUnsafeBytes { _ -> Void in throw failure }) { error in
        XCTAssertEqual(error as NSError, failure)
      }
      XCTAssertEqual(try plane.withUnsafeBytes { $0.count }, plane.bytesPerRow * plane.height)
    }
  }

  func testPackedBufferHasNoPlanes() throws {
    let frame = try makeFrame()
    XCTAssertTrue(try frame.planes.isEmpty)
    XCTAssertThrowsError(try FramePlane(pixelBuffer: XCTUnwrap(frame.pixelBuffer), index: 0)) { error in
      guard case .planeAccessRequiresPlanarBuffer? = error as? MediaError else {
        return XCTFail("Expected a planar-buffer requirement error")
      }
    }
  }

  func testNativeInvalidationRejectsImageAccessButPreservesRetainedPixelBuffer() async throws {
    let frame = try makeFrame()
    let pixelBuffer = try XCTUnwrap(frame.pixelBuffer)
    CMSampleBufferInvalidate(frame.sampleBuffer)
    XCTAssertFalse(frame.isValid)
    XCTAssertThrowsError(try frame.withUnsafeBytes { $0.count }) { error in
      guard case .invalidSampleBuffer? = error as? MediaError else {
        return XCTFail("Expected the native-invalidity error")
      }
    }
    do {
      _ = try await FrameConverter.image(from: frame)
      XCTFail("An invalid native sample cannot be rendered")
    } catch MediaError.invalidSampleBuffer {
      XCTAssertEqual(CVPixelBufferGetWidth(pixelBuffer), 8)
    }
  }

  func testSampleWithoutImageUsesOptionalNativeImageProperties() throws {
    var sampleBuffer: CMSampleBuffer?
    XCTAssertEqual(
      CMSampleBufferCreate(
        allocator: kCFAllocatorDefault, dataBuffer: nil, dataReady: true,
        makeDataReadyCallback: nil, refcon: nil, formatDescription: nil, sampleCount: 0,
        sampleTimingEntryCount: 0, sampleTimingArray: nil, sampleSizeEntryCount: 0,
        sampleSizeArray: nil, sampleBufferOut: &sampleBuffer), noErr)
    let metadata = MediaSampleMetadata(timestamp: .zero, orientation: .up, isMirrored: false)
    let frame = Frame(sampleBuffer: try XCTUnwrap(sampleBuffer), metadata: metadata)
    XCTAssertTrue(frame.isValid)
    XCTAssertNil(frame.pixelBuffer)
    XCTAssertNil(frame.width)
    XCTAssertNil(frame.height)
    XCTAssertNil(frame.byteCount)
    XCTAssertThrowsError(try frame.planes) { error in
      guard case .missingPixelBuffer? = error as? MediaError else {
        return XCTFail("An image-free sample must report its missing pixel buffer")
      }
    }
  }

  private func makeFrame(pixelFormat: OSType = kCVPixelFormatType_32BGRA) throws -> Frame {
    var pixelBuffer: CVPixelBuffer?
    let status = CVPixelBufferCreate(kCFAllocatorDefault, 8, 4, pixelFormat, nil, &pixelBuffer)
    XCTAssertEqual(status, kCVReturnSuccess)
    return try makeFrame(pixelBuffer: XCTUnwrap(pixelBuffer))
  }

  private func makeFrame(pixelBuffer: CVPixelBuffer) throws -> Frame {
    let format = try CMFormatDescription(imageBuffer: pixelBuffer)
    let timing = CMSampleTimingInfo(
      duration: CMTime(value: 1, timescale: 30),
      presentationTimeStamp: CMTime(value: 1, timescale: 30),
      decodeTimeStamp: .invalid)
    let sampleBuffer = try CMSampleBuffer(
      imageBuffer: pixelBuffer, formatDescription: format, sampleTiming: timing)
    let metadata = MediaSampleMetadata(
      timestamp: timing.presentationTimeStamp, orientation: .up, isMirrored: false)
    return Frame(sampleBuffer: sampleBuffer, metadata: metadata)
  }

  private func makeTrackedFrame(released: XCTestExpectation) throws -> Frame {
    let byteCount = 8 * 4 * 4
    let bytes = UnsafeMutableRawPointer.allocate(byteCount: byteCount, alignment: 64)
    bytes.initializeMemory(as: UInt8.self, repeating: 0x2A, count: byteCount)
    let context = Unmanaged.passRetained(released).toOpaque()
    var pixelBuffer: CVPixelBuffer?
    let status = CVPixelBufferCreateWithBytes(
      kCFAllocatorDefault, 8, 4, kCVPixelFormatType_32BGRA, bytes, 8 * 4,
      { context, bytes in
        UnsafeMutableRawPointer(mutating: bytes)?.deallocate()
        if let context {
          Unmanaged<XCTestExpectation>.fromOpaque(context).takeRetainedValue().fulfill()
        }
      }, context, nil, &pixelBuffer)
    guard status == kCVReturnSuccess, let pixelBuffer else {
      bytes.deallocate()
      Unmanaged<XCTestExpectation>.fromOpaque(context).release()
      throw NSError(domain: "BufferTests", code: Int(status))
    }
    return try makeFrame(pixelBuffer: pixelBuffer)
  }
}
