import AVFoundation
import CoreVideo
import XCTest

@testable import VisionCamera

final class NativeMetadataTests: XCTestCase {
  func testMetadataOptionsPreserveNativeAndFutureTypes() {
    let futureType = AVMetadataObject.ObjectType(rawValue: "VisionCameraTests.future-metadata")
    let options = ObjectOutputOptions(enabledObjectTypes: [.qr, .humanBody, futureType])
    XCTAssertEqual(options.enabledObjectTypes, [.qr, .humanBody, futureType])
  }

  func testCustomOutputMediaTypesRoundTripWithoutCoercion() {
    for nativeType in [AVMediaType.video, .depthData, .metadataObject, .audio, .init(rawValue: "future-media")] {
      XCTAssertEqual(MediaType(type: nativeType).toAVMediaType(), nativeType)
    }
  }

  func testSynchronizerRejectsUnsupportedAndDuplicateOutputsBeforeNativeSetup() {
    let frame = FrameOutput()
    for outputs: [any CameraOutput] in [
      [frame, PhotoOutput()],
      [frame, MovieFileVideoOutput()],
      [frame, frame],
    ] {
      XCTAssertThrowsError(try OutputSynchronizer(outputs: outputs)) { error in
        XCTAssertTrue(error is CaptureError)
      }
    }
  }

  func testSynchronizedMetadataPreservesTimestampAndEmptyResults() {
    let timestamp = CMTime(value: 17, timescale: 30)
    let data = SynchronizedDataFrame(
      data: .metadata([]),
      metadata: MediaSampleMetadata(timestamp: timestamp, orientation: .left, isMirrored: true)
    )
    guard case .metadata(let objects, let actualTimestamp) = data.synchronizedFrame else {
      return XCTFail("Metadata must remain a metadata sample")
    }
    XCTAssertTrue(objects.isEmpty)
    XCTAssertEqual(actualTimestamp, timestamp)
  }

  func testSynchronizerAcceptsNativeAudioAndSingleOutputBeforeConnectionValidation() {
    for output: any CameraOutput in [FrameOutput(), NativeAudioOutputFixture()] {
      XCTAssertThrowsError(try OutputSynchronizer(outputs: [output])) { error in
        guard case .synchronizedOutputNotConnected(let index)? = error as? CaptureError else {
          return XCTFail("Expected a disconnected native data output")
        }
        XCTAssertEqual(index, 0)
      }
    }
  }

  func testSynchronizedAudioPreservesTheNativeSampleAndTimestamp() throws {
    let timestamp = CMTime(value: 9, timescale: 48_000)
    var format = AudioStreamBasicDescription(
      mSampleRate: 48_000, mFormatID: kAudioFormatLinearPCM,
      mFormatFlags: kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked,
      mBytesPerPacket: 2, mFramesPerPacket: 1, mBytesPerFrame: 2,
      mChannelsPerFrame: 1, mBitsPerChannel: 16, mReserved: 0)
    var description: CMAudioFormatDescription?
    XCTAssertEqual(
      CMAudioFormatDescriptionCreate(
        allocator: kCFAllocatorDefault, asbd: &format,
        layoutSize: 0, layout: nil, magicCookieSize: 0, magicCookie: nil,
        extensions: nil, formatDescriptionOut: &description), noErr)
    var buffer: CMSampleBuffer?
    var timing = CMSampleTimingInfo(duration: CMTime(value: 1, timescale: 48_000), presentationTimeStamp: timestamp, decodeTimeStamp: .invalid)
    var size = 2
    XCTAssertEqual(
      CMSampleBufferCreateReady(
        allocator: kCFAllocatorDefault, dataBuffer: nil,
        formatDescription: try XCTUnwrap(description), sampleCount: 1,
        sampleTimingEntryCount: 1, sampleTimingArray: &timing,
        sampleSizeEntryCount: 1, sampleSizeArray: &size, sampleBufferOut: &buffer), noErr)
    let original = try XCTUnwrap(buffer)
    let data = SynchronizedDataFrame(
      data: .audio(original), metadata: MediaSampleMetadata(timestamp: timestamp, orientation: .up, isMirrored: false))
    guard case .audio(let delivered) = data.synchronizedFrame else {
      return XCTFail("Audio must remain an audio sample")
    }
    XCTAssertTrue(original === delivered)
    XCTAssertEqual(CMSampleBufferGetPresentationTimeStamp(delivered), timestamp)
    XCTAssertEqual(CMFormatDescriptionGetMediaType(try XCTUnwrap(CMSampleBufferGetFormatDescription(delivered))), kCMMediaType_Audio)
  }

  func testSynchronizedFrameUsesTheOutputsRequestedTransform() throws {
    let output = FrameOutput()
    output.outputOrientation = .right
    try output.configure(.init(mirrorMode: .on))
    let delegate = SynchronizedOutputDelegate(outputs: [output])
    let timestamp = CMTime(value: 17, timescale: 30)
    let regular = output.getMediaSampleMetadata(at: timestamp, orientation: .up, isMirrored: false)
    let synchronized = delegate.metadata(at: timestamp, from: output.output, bufferOrientation: .up, isBufferMirrored: false)
    XCTAssertEqual(synchronized.orientation, .left)
    XCTAssertTrue(synchronized.isMirrored)
    XCTAssertEqual(synchronized.orientation, regular.orientation)
    XCTAssertEqual(synchronized.isMirrored, regular.isMirrored)
    XCTAssertEqual(synchronized.timestamp, timestamp)

    let alreadyTransformed = delegate.metadata(at: timestamp, from: output.output, bufferOrientation: .right, isBufferMirrored: true)
    XCTAssertEqual(alreadyTransformed.orientation, .up)
    XCTAssertFalse(alreadyTransformed.isMirrored)
  }

  func testSynchronizedDepthUsesTheOutputsRequestedTransform() throws {
    let output = DepthOutput()
    output.outputOrientation = .down
    try output.configure(.init(mirrorMode: .off))
    let delegate = SynchronizedOutputDelegate(outputs: [output])
    let timestamp = CMTime(value: 17, timescale: 30)
    let regular = output.getMediaSampleMetadata(at: timestamp, orientation: .up, isMirrored: true)
    let synchronized = delegate.metadata(at: timestamp, from: output.output, bufferOrientation: .up, isBufferMirrored: true)
    XCTAssertEqual(synchronized.orientation, .down)
    XCTAssertTrue(synchronized.isMirrored)
    XCTAssertEqual(synchronized.orientation, regular.orientation)
    XCTAssertEqual(synchronized.isMirrored, regular.isMirrored)
    XCTAssertEqual(synchronized.timestamp, timestamp)
  }

  func testIntrinsicMatrixReadsNativeColumnsAndRejectsMalformedAttachments() throws {
    let buffer = try makeSampleBuffer()
    XCTAssertNil(buffer.cameraIntrinsicMatrix)
    var expected = simd_float3x3(
      SIMD3<Float>(100, 0, 0), SIMD3<Float>(0, 200, 0), SIMD3<Float>(3, 4, 1))
    let bytes = withUnsafeBytes(of: &expected) { Data($0) }
    CMSetAttachment(buffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, value: bytes as CFData, attachmentMode: kCMAttachmentMode_ShouldPropagate)
    let actual = try XCTUnwrap(buffer.cameraIntrinsicMatrix)
    XCTAssertEqual(actual.columns.0, expected.columns.0)
    XCTAssertEqual(actual.columns.1, expected.columns.1)
    XCTAssertEqual(actual.columns.2, expected.columns.2)

    CMSetAttachment(
      buffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, value: Data([1, 2, 3]) as CFData, attachmentMode: kCMAttachmentMode_ShouldPropagate)
    XCTAssertNil(buffer.cameraIntrinsicMatrix)
  }

  private func makeSampleBuffer() throws -> CMSampleBuffer {
    var pixelBuffer: CVPixelBuffer?
    XCTAssertEqual(CVPixelBufferCreate(kCFAllocatorDefault, 8, 4, kCVPixelFormatType_32BGRA, nil, &pixelBuffer), kCVReturnSuccess)
    let buffer = try XCTUnwrap(pixelBuffer)
    return try CMSampleBuffer(
      imageBuffer: buffer,
      formatDescription: CMFormatDescription(imageBuffer: buffer),
      sampleTiming: CMSampleTimingInfo(duration: .invalid, presentationTimeStamp: .zero, decodeTimeStamp: .invalid))
  }
}
