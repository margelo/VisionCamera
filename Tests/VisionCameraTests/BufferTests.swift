import AVFoundation
import CoreVideo
import VisionCamera
import XCTest

final class BufferTests: XCTestCase {
  func testDisposalDoesNotInvalidateRetainedNativeBuffers() throws {
    let frame = try makeFrame()
    let sampleBuffer = try XCTUnwrap(frame.sampleBuffer)
    let pixelBuffer = try frame.getPixelBuffer()

    frame.dispose()
    frame.dispose()

    XCTAssertFalse(frame.isValid)
    XCTAssertNil(frame.sampleBuffer)
    XCTAssertThrowsError(try frame.getPixelBuffer())
    XCTAssertThrowsError(try frame.withUnsafeBytes { $0.count })
    XCTAssertTrue(CMSampleBufferIsValid(sampleBuffer))
    XCTAssertEqual(CVPixelBufferGetWidth(pixelBuffer), 8)
  }

  func testPackedBytesRemainAliveThroughoutScopeAndReleaseAfterward() throws {
    let released = expectation(description: "Native pixel memory was released")
    let frame = try makeTrackedFrame(released: released)

    let data = try frame.withUnsafeBytes { bytes in
      frame.dispose()
      XCTAssertEqual(bytes.count, 8 * 4 * 4)
      XCTAssertEqual(bytes.first, 0x2A)
      return Data(bytes)
    }

    XCTAssertEqual(data, Data(repeating: 0x2A, count: 8 * 4 * 4))
    wait(for: [released], timeout: 1)
  }

  func testThrowingByteScopeStillReleasesNativeMemory() throws {
    let released = expectation(description: "Native pixel memory was released after a throwing scope")
    let frame = try makeTrackedFrame(released: released)
    let failure = NSError(domain: "BufferTests", code: 1)

    XCTAssertThrowsError(
      try frame.withUnsafeBytes { _ -> Void in
        frame.dispose()
        throw failure
      }
    ) { error in
      XCTAssertEqual(error as NSError, failure)
    }

    wait(for: [released], timeout: 1)
  }

  func testARCReleasesFrameWithoutExplicitDisposal() throws {
    let released = expectation(description: "ARC released the pixel buffer")
    try autoreleasepool {
      let frame = try makeTrackedFrame(released: released)
      XCTAssertTrue(frame.isValid)
      XCTAssertEqual(try frame.withUnsafeBytes { $0.count }, 8 * 4 * 4)
    }
    wait(for: [released], timeout: 1)
  }

  func testPlanarBoundsAndIndependentPlaneLifetime() throws {
    let frame = try makeFrame(pixelFormat: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
    let pixelBuffer = try frame.getPixelBuffer()
    XCTAssertThrowsError(try FramePlane(buffer: pixelBuffer, planeIndex: -1))
    XCTAssertThrowsError(try FramePlane(buffer: pixelBuffer, planeIndex: 2))
    XCTAssertThrowsError(try frame.withUnsafeBytes { $0.count })

    let planes = try frame.getPlanes()
    XCTAssertEqual(planes.count, 2)
    XCTAssertEqual(planes[0].width, 8)
    XCTAssertEqual(planes[0].height, 4)
    XCTAssertEqual(planes[1].width, 4)
    XCTAssertEqual(planes[1].height, 2)

    frame.dispose()
    XCTAssertTrue(planes[0].isValid)
    XCTAssertEqual(try planes[0].withUnsafeBytes { $0.count }, Int(planes[0].bytesPerRow * planes[0].height))
    XCTAssertEqual(try planes[1].withUnsafeBytes { $0.count }, Int(planes[1].bytesPerRow * planes[1].height))

    planes[0].dispose()
    planes[0].dispose()
    XCTAssertThrowsError(try planes[0].withUnsafeBytes { $0.count })
    XCTAssertTrue(planes[1].isValid)
  }

  func testPackedBufferHasNoPlanes() throws {
    let frame = try makeFrame()
    XCTAssertTrue(try frame.getPlanes().isEmpty)
    XCTAssertThrowsError(try FramePlane(buffer: frame.getPixelBuffer(), planeIndex: 0))
  }

  func testStaticFrameConverterRejectsDisposedFrames() async throws {
    let frame = try makeFrame()
    frame.dispose()

    XCTAssertThrowsError(try FrameConverter.convertFrameToImage(frame: frame)) { error in
      XCTAssertTrue(error is CameraError)
    }
    do {
      _ = try await FrameConverter.convertFrameToImageAsync(frame: frame)
      XCTFail("A disposed Frame cannot be converted to an image")
    } catch {
      XCTAssertTrue(error is CameraError)
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
    return Frame(buffer: sampleBuffer, metadata: metadata)
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
