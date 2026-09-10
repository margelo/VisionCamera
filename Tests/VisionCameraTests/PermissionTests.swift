import Foundation
import XCTest

@testable import VisionCamera

final class PermissionTests: XCTestCase {
  func testUsageDescriptionPreflightRejectsMissingBlankAndNonStringValues() throws {
    for value: Any? in [nil, "", "   ", 42] {
      try withBundle(usageDescription: value) { bundle in
        XCTAssertThrowsError(try bundle.requireCameraUsageDescription()) { error in
          guard case .missingUsageDescription(let key)? = error as? PermissionError else {
            return XCTFail("Expected a usage-description error")
          }
          XCTAssertEqual(key, "NSCameraUsageDescription")
        }
        XCTAssertThrowsError(try bundle.requireMicrophoneUsageDescription()) { error in
          guard case .missingUsageDescription(let key)? = error as? PermissionError else {
            return XCTFail("Expected a usage-description error")
          }
          XCTAssertEqual(key, "NSMicrophoneUsageDescription")
        }
      }
    }
  }

  func testUsageDescriptionPreflightAcceptsHumanReadableStringsWithoutRequestingAccess() throws {
    try withBundle(usageDescription: "Capture photos and videos.") { bundle in
      XCTAssertNoThrow(try bundle.requireCameraUsageDescription())
      XCTAssertNoThrow(try bundle.requireMicrophoneUsageDescription())
    }
  }

  private func withBundle(usageDescription: Any?, _ body: (Bundle) throws -> Void) throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".bundle", isDirectory: true)
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: url) }
    var properties: [String: Any] = ["CFBundleIdentifier": "com.margelo.VisionCameraTests.\(UUID().uuidString)"]
    properties["NSCameraUsageDescription"] = usageDescription
    properties["NSMicrophoneUsageDescription"] = usageDescription
    let data = try PropertyListSerialization.data(fromPropertyList: properties, format: .xml, options: 0)
    try data.write(to: url.appendingPathComponent("Info.plist"))
    try body(XCTUnwrap(Bundle(url: url)))
  }
}
