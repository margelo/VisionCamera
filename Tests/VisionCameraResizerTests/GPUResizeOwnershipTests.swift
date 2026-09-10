import Foundation
import VisionCameraResizer
import XCTest

final class GPUResizeOwnershipTests: XCTestCase {
  func testBoundedPoolKeepsResultsIndependentAndReusesReleasedAllocation() throws {
    try ResizerTestImage.requireMetal()
    let resizer = try GPUResizer(options: ResizerOptions(width: 4, height: 2), maximumOutstandingResults: 2)
    let dark = try ResizerTestImage.make(luma: Array(repeating: 20, count: 8))
    let light = try ResizerTestImage.make(luma: Array(repeating: 230, count: 8))
    var first: GPUResizeResult? = try resizer.resize(dark)
    let bufferID = try XCTUnwrap(first).withMetalBuffer { ObjectIdentifier($0) }
    let second = try resizer.resize(light)
    ResizerTestImage.assertLuma(try XCTUnwrap(first), Array(repeating: 20, count: 8))
    ResizerTestImage.assertLuma(second, Array(repeating: 230, count: 8))
    XCTAssertThrowsError(try resizer.resize(dark)) { error in
      XCTAssertEqual(error as? GPUResizerError, .outputCapacityExceeded)
    }
    first = nil
    let third = try resizer.resize(dark)
    XCTAssertEqual(third.withMetalBuffer { ObjectIdentifier($0) }, bufferID)
    ResizerTestImage.assertLuma(second, Array(repeating: 230, count: 8))
    withExtendedLifetime((second, third)) {}
  }

  func testResultSurvivesSourceAndResizerLifetime() throws {
    try ResizerTestImage.requireMetal()
    let result = try autoreleasepool {
      let input = try ResizerTestImage.make(luma: Array(repeating: 100, count: 8))
      let frame = try ResizerTestImage.frame(input)
      let resizer = try GPUResizer(options: ResizerOptions(width: 4, height: 2))
      let result = try resizer.resize(frame)
      frame.dispose()
      return result
    }
    ResizerTestImage.assertLuma(result, Array(repeating: 100, count: 8))
  }

  func testByteScopeRetainsLeaseUntilReturningAndThrowingScopeReleasesIt() throws {
    try ResizerTestImage.requireMetal()
    let input = try ResizerTestImage.make(luma: Array(repeating: 100, count: 8))
    let resizer = try GPUResizer(options: ResizerOptions(width: 4, height: 2), maximumOutstandingResults: 1)
    var result: GPUResizeResult? = try resizer.resize(input)
    let copied = try XCTUnwrap(result).withUnsafeBytes { bytes in
      result = nil
      XCTAssertThrowsError(try resizer.resize(input)) { error in
        XCTAssertEqual(error as? GPUResizerError, .outputCapacityExceeded)
      }
      return Data(bytes)
    }
    XCTAssertEqual(copied.count, 24)
    let failure = NSError(domain: "GPUResizeOwnershipTests", code: 1)
    XCTAssertThrowsError(try resizer.resize(input).withUnsafeBytes { _ -> Void in throw failure })
    let next = try resizer.resize(input)
    XCTAssertEqual(next.withUnsafeBytes { Data($0) }, copied)
  }
}
