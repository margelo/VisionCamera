import AVFoundation
import Foundation
import VisionCamera
import XCTest

final class ObservationTests: XCTestCase {
  func testCancellationAndARCPerformCleanupExactlyOnce() {
    var cancellationCount = 0
    var token: ObservationToken? = ObservationToken { cancellationCount += 1 }
    let isReleased = { [weak token] in token == nil }
    token?.cancel()
    token?.cancel()
    XCTAssertEqual(cancellationCount, 1)
    token = nil
    XCTAssertTrue(isReleased())
    XCTAssertEqual(cancellationCount, 1)
  }

  func testReleasingTheLastTokenReferenceCancelsObservation() {
    var cancellationCount = 0
    autoreleasepool {
      let token = ObservationToken { cancellationCount += 1 }
      withExtendedLifetime(token) { XCTAssertEqual(cancellationCount, 0) }
    }
    XCTAssertEqual(cancellationCount, 1)
  }

  func testConcurrentCancellationInvokesCleanupOnce() {
    let cancelled = expectation(description: "The observation was cancelled")
    cancelled.assertForOverFulfill = true
    let token = ObservationToken { cancelled.fulfill() }
    DispatchQueue.concurrentPerform(iterations: 64) { _ in token.cancel() }
    token.cancel()
    wait(for: [cancelled], timeout: 1)
  }

  @MainActor
  func testSessionObservationStopsWhenTheTokenIsReleased() async {
    let session = CameraSession()
    var receivedEvents = 0
    var token: ObservationToken? = session.observeStarted { receivedEvents += 1 }
    XCTAssertNotNil(token)
    NotificationCenter.default.post(name: AVCaptureSession.didStartRunningNotification, object: session.session)
    XCTAssertEqual(receivedEvents, 1)
    token = nil
    NotificationCenter.default.post(name: AVCaptureSession.didStartRunningNotification, object: session.session)
    XCTAssertEqual(receivedEvents, 1)
  }

  func testCancellationCanReenterAndReleasesCapturedObjects() {
    var token: ObservationToken?
    weak var weakPayload: NSObject?
    var cancellationCount = 0
    autoreleasepool {
      let payload = NSObject()
      weakPayload = payload
      token = ObservationToken { [payload] in
        _ = payload
        token?.cancel()
        cancellationCount += 1
      }
    }
    XCTAssertNotNil(weakPayload)
    token?.cancel()
    XCTAssertEqual(cancellationCount, 1)
    XCTAssertNil(weakPayload)
    token = nil
  }
}
