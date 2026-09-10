import Foundation
import Vision
import XCTest

@testable import VisionCameraBarcodeScanner

@available(iOS 16.0, *)
final class BarcodeScanStateTests: XCTestCase {
  func testConcurrentCallsRejectNewWorkWithoutQueuing() throws {
    let state = BarcodeScanState()
    try state.begin(VNDetectBarcodesRequest())
    DispatchQueue.concurrentPerform(iterations: 20) { _ in
      do {
        try state.begin(VNDetectBarcodesRequest())
        XCTFail("A concurrent scan was accepted while another scan was active.")
      } catch {
        guard case BarcodeScannerError.busy = error else { return XCTFail("Unexpected error: \(error)") }
      }
    }
    XCTAssertFalse(state.finish())
    XCTAssertNoThrow(try state.begin(VNDetectBarcodesRequest()))
    XCTAssertFalse(state.finish())
  }

  func testCancellationIsScopedToAcceptedOperationAndDoesNotCancelNextScan() throws {
    let state = BarcodeScanState()
    state.cancel()
    try state.begin(VNDetectBarcodesRequest())
    XCTAssertFalse(state.finish())
    try state.begin(VNDetectBarcodesRequest())
    DispatchQueue.concurrentPerform(iterations: 20) { _ in state.cancel() }
    XCTAssertTrue(state.finish())
    try state.begin(VNDetectBarcodesRequest())
    XCTAssertFalse(state.finish())
    state.cancel()
    try state.begin(VNDetectBarcodesRequest())
    XCTAssertFalse(state.finish())
  }
}
