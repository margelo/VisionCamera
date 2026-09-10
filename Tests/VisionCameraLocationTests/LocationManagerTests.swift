import CoreLocation
import Foundation
import XCTest

@testable import VisionCameraLocation

final class LocationManagerTests: XCTestCase {
  @MainActor
  func testConstructionHasNoPermissionOrUpdateSideEffects() {
    let driver = FakeLocationDriver()
    var validations = 0
    let manager = LocationManager(driver: driver) { validations += 1 }

    XCTAssertEqual(manager.authorizationStatus, .notDetermined)
    XCTAssertNil(manager.lastKnownLocation)
    XCTAssertFalse(manager.isUpdating)
    XCTAssertEqual(validations, 0)
    XCTAssertEqual(driver.authorizationRequests, 0)
    XCTAssertEqual(driver.starts, 0)
  }

  @MainActor
  func testExplicitPermissionRequestDoesNotStartUpdatesOrInventAGrant() throws {
    let driver = FakeLocationDriver()
    let manager = LocationManager(driver: driver) {}
    var observed: [CLAuthorizationStatus] = []
    manager.onAuthorizationChanged = { status, _ in observed.append(status) }

    try manager.requestWhenInUseAuthorization()
    XCTAssertEqual(driver.authorizationRequests, 1)
    XCTAssertEqual(manager.authorizationStatus, .notDetermined)
    XCTAssertTrue(observed.isEmpty)
    XCTAssertEqual(driver.starts, 0)

    // Core Location emits an initial event before the user makes a choice.
    driver.sendAuthorization(.notDetermined)
    XCTAssertEqual(manager.authorizationStatus, .notDetermined)
    XCTAssertEqual(observed, [.notDetermined])

    driver.sendAuthorization(.authorizedWhenInUse, accuracy: .reducedAccuracy)
    XCTAssertEqual(manager.authorizationStatus, .authorizedWhenInUse)
    XCTAssertEqual(manager.accuracyAuthorization, .reducedAccuracy)
    XCTAssertFalse(manager.isUpdating)
    XCTAssertEqual(driver.starts, 0)
  }

  @MainActor
  func testDeterminedAuthorizationDoesNotRequestAgain() throws {
    for status: CLAuthorizationStatus in [.denied, .restricted, .authorizedWhenInUse, .authorizedAlways] {
      let driver = FakeLocationDriver()
      driver.authorizationStatus = status
      let manager = LocationManager(driver: driver) {}
      try manager.requestWhenInUseAuthorization()
      XCTAssertEqual(driver.authorizationRequests, 0)
    }
  }

  @MainActor
  func testMissingPurposeStringPreventsNativePermissionRequest() {
    let driver = FakeLocationDriver()
    let manager = LocationManager(driver: driver) { throw LocationManagerError.missingUsageDescription }
    XCTAssertThrowsError(try manager.requestWhenInUseAuthorization()) { error in
      XCTAssertEqual(error as? LocationManagerError, .missingUsageDescription)
    }
    XCTAssertEqual(driver.authorizationRequests, 0)
  }

  @MainActor
  func testStartingWithoutAuthorizationNeverImplicitlyRequestsPermission() {
    for status: CLAuthorizationStatus in [.notDetermined, .denied, .restricted] {
      let driver = FakeLocationDriver()
      driver.authorizationStatus = status
      let manager = LocationManager(driver: driver) {}
      XCTAssertThrowsError(try manager.startUpdating()) { error in
        XCTAssertEqual(error as? LocationManagerError, .notAuthorized(status))
      }
      XCTAssertFalse(manager.isUpdating)
      XCTAssertEqual(driver.authorizationRequests, 0)
      XCTAssertEqual(driver.starts, 0)
    }
  }

  @MainActor
  func testStartingRequiresPurposeStringEvenWithPriorAuthorization() {
    let driver = FakeLocationDriver()
    driver.authorizationStatus = .authorizedWhenInUse
    let manager = LocationManager(driver: driver) { throw LocationManagerError.missingUsageDescription }
    XCTAssertThrowsError(try manager.startUpdating()) { error in
      XCTAssertEqual(error as? LocationManagerError, .missingUsageDescription)
    }
    XCTAssertFalse(manager.isUpdating)
    XCTAssertEqual(driver.starts, 0)
  }

  @MainActor
  func testStartAndStopAreIdempotentAndSuppressLateEvents() throws {
    let driver = FakeLocationDriver()
    driver.authorizationStatus = .authorizedWhenInUse
    let manager = LocationManager(driver: driver) {}
    var callbacks = 0
    manager.onLocationChanged = { _ in callbacks += 1 }
    manager.onError = { _ in XCTFail("Errors queued before stop must be suppressed") }
    try manager.startUpdating()
    try manager.startUpdating()
    XCTAssertEqual(driver.starts, 1)

    let location = CLLocation(latitude: 48.2, longitude: 16.3)
    driver.onLocations?([location])
    XCTAssertTrue(manager.lastKnownLocation === location)
    XCTAssertEqual(callbacks, 1)
    manager.stopUpdating()
    manager.stopUpdating()
    XCTAssertFalse(manager.isUpdating)
    XCTAssertEqual(driver.stops, 1)
    driver.onLocations?([CLLocation(latitude: 48.3, longitude: 16.4)])
    driver.onError?(CLError(.locationUnknown))
    XCTAssertTrue(manager.lastKnownLocation === location)
    XCTAssertEqual(callbacks, 1)
  }

  @MainActor
  func testNewestValidLocationIsAnOwnedNativeValue() throws {
    let driver = FakeLocationDriver()
    driver.authorizationStatus = .authorizedWhenInUse
    var manager: LocationManager? = LocationManager(driver: driver) {}
    var retainedLocation: CLLocation?
    manager?.onLocationChanged = { retainedLocation = $0 }
    try manager?.startUpdating()

    let old = CLLocation(latitude: 48.1, longitude: 16.1)
    let new = CLLocation(latitude: 48.2, longitude: 16.2)
    let invalid = CLLocation(
      coordinate: .init(latitude: 0, longitude: 0), altitude: 0,
      horizontalAccuracy: -1, verticalAccuracy: -1, timestamp: Date())
    driver.onLocations?([old, new, invalid])
    XCTAssertTrue(retainedLocation === new)
    XCTAssertTrue(manager?.lastKnownLocation === new)
    driver.onLocations?([])
    driver.onLocations?([invalid])
    XCTAssertTrue(manager?.lastKnownLocation === new)
    manager = nil
    XCTAssertTrue(retainedLocation === new)
    XCTAssertEqual(driver.stops, 1)
    XCTAssertNil(driver.onLocations)
    XCTAssertNil(driver.onAuthorization)
    XCTAssertNil(driver.onError)
  }

  @MainActor
  func testPermissionRevocationStopsBeforeCallbackAndClearsLocation() throws {
    let driver = FakeLocationDriver()
    driver.authorizationStatus = .authorizedWhenInUse
    driver.location = CLLocation(latitude: 48.2, longitude: 16.3)
    let manager = LocationManager(driver: driver) {}
    try manager.startUpdating()
    manager.onAuthorizationChanged = { [weak manager] status, accuracy in
      XCTAssertEqual(status, .denied)
      XCTAssertEqual(accuracy, .reducedAccuracy)
      XCTAssertEqual(manager?.authorizationStatus, .denied)
      XCTAssertFalse(manager?.isUpdating ?? true)
      XCTAssertNil(manager?.lastKnownLocation)
      XCTAssertEqual(driver.stops, 1)
    }
    driver.sendAuthorization(.denied, accuracy: .reducedAccuracy)
  }

  @MainActor
  func testTransientErrorsContinueAndDenialStopsUpdates() throws {
    let driver = FakeLocationDriver()
    driver.authorizationStatus = .authorizedWhenInUse
    let manager = LocationManager(driver: driver) {}
    var failures: [CLError.Code] = []
    manager.onError = { error in failures.append((error as! CLError).code) }
    try manager.startUpdating()
    driver.onError?(CLError(.locationUnknown))
    XCTAssertTrue(manager.isUpdating)
    XCTAssertEqual(driver.stops, 0)
    driver.onError?(CLError(.denied))
    XCTAssertFalse(manager.isUpdating)
    XCTAssertEqual(driver.stops, 1)
    XCTAssertEqual(failures, [.locationUnknown, .denied])
  }

  func testOptionsPreserveOriginalAccuracyAndDistanceSemantics() throws {
    XCTAssertEqual(LocationAccuracy.high.nativeValue, kCLLocationAccuracyBest)
    XCTAssertEqual(LocationAccuracy.balanced.nativeValue, kCLLocationAccuracyNearestTenMeters)
    XCTAssertEqual(LocationAccuracy.low.nativeValue, kCLLocationAccuracyHundredMeters)
    XCTAssertEqual(LocationManagerOptions().accuracy, .balanced)
    XCTAssertEqual(LocationManagerOptions().distanceFilter, 10)
    for distance in [0, 10, kCLDistanceFilterNone] {
      XCTAssertNoThrow(try LocationManagerOptions(distanceFilter: distance).validate())
    }
    for distance: CLLocationDistance in [-2, .nan, .infinity, -.infinity] {
      XCTAssertThrowsError(try LocationManagerOptions(distanceFilter: distance).validate()) { error in
        XCTAssertEqual(error as? LocationManagerError, .invalidDistanceFilter)
      }
    }
  }

  func testPurposeStringValidationRejectsAbsentWrongTypedAndBlankValues() throws {
    for value: Any? in [nil, 4, "", " \n\t"] {
      XCTAssertThrowsError(try LocationUsageDescription.validate(value)) { error in
        XCTAssertEqual(error as? LocationManagerError, .missingUsageDescription)
      }
    }
    XCTAssertNoThrow(try LocationUsageDescription.validate("Add capture coordinates to the photos you choose to geotag."))
  }
}
