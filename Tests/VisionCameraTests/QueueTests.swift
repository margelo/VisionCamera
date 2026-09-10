import Foundation
import XCTest

@testable import VisionCamera

final class QueueTests: XCTestCase {
  func testInfallibleWorkCompletesOnOwnerQueueEvenWhenCallerIsCancelled() async {
    let queue = DispatchQueue(label: "VisionCameraTests.infallible")
    let key = DispatchSpecificKey<Bool>()
    queue.setSpecific(key: key, value: true)

    let task = Task {
      withUnsafeCurrentTask { $0?.cancel() }
      XCTAssertTrue(Task.isCancelled)
      return await queue.perform {
        XCTAssertEqual(DispatchQueue.getSpecific(key: key), true)
        return 42
      }
    }

    let value = await task.value
    XCTAssertEqual(value, 42)
  }

  func testThrowingWorkPropagatesTheUnderlyingErrorFromOwnerQueue() async {
    let queue = DispatchQueue(label: "VisionCameraTests.fallible")
    let key = DispatchSpecificKey<Bool>()
    queue.setSpecific(key: key, value: true)
    let expectedError = NSError(domain: "VisionCameraTests", code: 42)

    do {
      try await queue.perform {
        XCTAssertEqual(DispatchQueue.getSpecific(key: key), true)
        throw expectedError
      }
      XCTFail("Expected the operation's error")
    } catch {
      XCTAssertEqual(error as NSError, expectedError)
    }
  }

  func testCancelledThrowingWorkDoesNotStart() async {
    let queue = DispatchQueue(label: "VisionCameraTests.cancelled")
    let task = Task { () async throws -> Void in
      withUnsafeCurrentTask { $0?.cancel() }
      try await queue.perform {
        XCTFail("Cancelled throwing work must not execute")
        throw NSError(domain: "VisionCameraTests.cancelled", code: 1)
      }
    }

    do {
      try await task.value
      XCTFail("Expected cancellation")
    } catch {
      XCTAssertTrue(error is CancellationError)
    }
  }
}
