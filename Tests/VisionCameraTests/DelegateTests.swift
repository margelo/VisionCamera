import AVFoundation
import XCTest

@testable import VisionCamera

final class DelegateTests: XCTestCase {
  func testVideoStartAndFinishAreDeliveredOnceOnTheOwnerQueue() async {
    let queue = DispatchQueue(label: "VisionCameraTests.video")
    let queueKey = DispatchSpecificKey<Bool>()
    queue.setSpecific(key: queueKey, value: true)
    var events: [String] = []
    var delegate: VideoDelegate? = VideoDelegate(
      queue: queue,
      onRecordingStarted: {
        XCTAssertEqual(DispatchQueue.getSpecific(key: queueKey), true)
        events.append("started")
      },
      onRecordingPaused: { events.append("paused") },
      onRecordingResumed: { events.append("resumed") },
      onRecordingFinished: { _, reason in
        XCTAssertEqual(DispatchQueue.getSpecific(key: queueKey), true)
        XCTAssertEqual(reason, .stopped)
        events.append("finished")
      },
      onRecordingError: { error in XCTFail("Unexpected recording error: \(error)") }
    )
    let isDelegateReleased = { [weak delegate] in delegate == nil }
    let output = AVCaptureMovieFileOutput()
    let url = URL(fileURLWithPath: "/tmp/vision-camera-delegate-test.mov")
    delegate?.fileOutput(output, didStartRecordingTo: url, from: [])
    delegate?.fileOutput(output, didStartRecordingTo: url, from: [])
    delegate?.fileOutput(output, didPauseRecordingTo: url, from: [])
    delegate?.fileOutput(output, didResumeRecordingTo: url, from: [])
    delegate?.fileOutput(output, didFinishRecordingTo: url, from: [], error: nil)
    delegate?.fileOutput(output, didFinishRecordingTo: url, from: [], error: nil)
    delegate?.fileOutput(output, didPauseRecordingTo: url, from: [])
    delegate?.fileOutput(output, didResumeRecordingTo: url, from: [])
    await drain(queue)
    XCTAssertEqual(events, ["started", "paused", "resumed", "finished"])
    delegate = nil
    XCTAssertTrue(isDelegateReleased())
  }

  func testRecordingFailureBeforeStartSuppressesLateCallbacks() async {
    let queue = DispatchQueue(label: "VisionCameraTests.failed-video")
    let expectedError = NSError(domain: "VisionCameraTests", code: 42)
    var errors: [NSError] = []
    let delegate = VideoDelegate(
      queue: queue,
      onRecordingStarted: { XCTFail("Recording started after failure") },
      onRecordingPaused: nil,
      onRecordingResumed: nil,
      onRecordingFinished: { _, _ in XCTFail("Failed recording finished successfully") },
      onRecordingError: { errors.append($0 as NSError) }
    )
    let output = AVCaptureMovieFileOutput()
    let url = URL(fileURLWithPath: "/tmp/vision-camera-delegate-test.mov")
    delegate.fileOutput(output, didFinishRecordingTo: url, from: [], error: expectedError)
    delegate.fileOutput(output, didStartRecordingTo: url, from: [])
    delegate.fileOutput(output, didFinishRecordingTo: url, from: [], error: expectedError)
    await drain(queue)
    XCTAssertEqual(errors, [expectedError])
  }

  func testNativeRecordingLimitsFinishWithTheMatchingReason() async {
    let queue = DispatchQueue(label: "VisionCameraTests.recording-limits")
    let cases: [(AVError.Code, RecordingFinishedReason)] = [
      (.maximumDurationReached, .maxDurationReached),
      (.maximumFileSizeReached, .maxFileSizeReached),
    ]
    for (errorCode, expectedReason) in cases {
      var finishedReason: RecordingFinishedReason?
      let delegate = VideoDelegate(
        queue: queue,
        onRecordingStarted: {},
        onRecordingPaused: nil,
        onRecordingResumed: nil,
        onRecordingFinished: { _, reason in finishedReason = reason },
        onRecordingError: { error in XCTFail("Recording limit failed: \(error)") }
      )
      let output = AVCaptureMovieFileOutput()
      let url = URL(fileURLWithPath: "/tmp/vision-camera-delegate-test.mov")
      let error = NSError(domain: AVFoundationErrorDomain, code: errorCode.rawValue)
      delegate.fileOutput(output, didFinishRecordingTo: url, from: [], error: error)
      await drain(queue)
      XCTAssertEqual(finishedReason, expectedReason)
    }
  }

  func testPhotoCaptureWithoutPhotoReportsOneErrorAndReleasesTheDelegate() async {
    let queue = DispatchQueue(label: "VisionCameraTests.empty-photo")
    let queueKey = DispatchSpecificKey<Bool>()
    queue.setSpecific(key: queueKey, value: true)
    var errors: [any Error] = []
    var finishedCount = 0
    var delegate: CapturePhotoDelegate? = CapturePhotoDelegate(
      queue: queue,
      onCaptured: { _, _ in XCTFail("Capture completed without a photo") },
      onError: {
        XCTAssertEqual(DispatchQueue.getSpecific(key: queueKey), true)
        errors.append($0)
      },
      onFinished: { finishedCount += 1 },
      callbacks: CapturePhotoCallbacks()
    )
    let isDelegateReleased = { [weak delegate] in delegate == nil }
    delegate?.finishCapture(error: nil)
    delegate?.finishCapture(error: nil)
    await drain(queue)
    XCTAssertEqual(errors.count, 1)
    guard case .missingPhoto? = errors.first as? CaptureError else {
      return XCTFail("Expected a missing-photo capture error")
    }
    XCTAssertEqual(finishedCount, 1)
    delegate = nil
    XCTAssertTrue(isDelegateReleased())
  }

  func testPhotoCapturePropagatesTheNativeTerminalError() async {
    let queue = DispatchQueue(label: "VisionCameraTests.failed-photo")
    let expectedError = NSError(domain: AVFoundationErrorDomain, code: AVError.deviceNotConnected.rawValue)
    var errors: [NSError] = []
    var finishedCount = 0
    let delegate = CapturePhotoDelegate(
      queue: queue,
      onCaptured: { _, _ in XCTFail("Failed capture produced a photo") },
      onError: { errors.append($0 as NSError) },
      onFinished: { finishedCount += 1 },
      callbacks: CapturePhotoCallbacks()
    )
    delegate.finishCapture(error: expectedError)
    delegate.finishCapture(error: expectedError)
    await drain(queue)
    XCTAssertEqual(errors, [expectedError])
    XCTAssertEqual(finishedCount, 1)
  }

  private func drain(_ queue: DispatchQueue) async {
    await withCheckedContinuation { continuation in
      queue.async { continuation.resume() }
    }
  }
}
