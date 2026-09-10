// Copyright © 2025 Marc Rousavy @ Margelo
// Adapted from react-native-vision-camera-location. See OPTIONAL_MODULES.md.

import CoreLocation
import Foundation

/// Collects foreground locations after the app explicitly requests permission.
///
/// The manager and all callbacks are isolated to the main actor. Core Location uses
/// the main thread's run loop to deliver delegate events. Keep callbacks short.
/// Construction does not request authorization or start location updates.
///
/// Retain the manager while collecting locations, then call ``stopUpdating()`` when
/// the feature closes. Releasing the manager also stops its updates; if the last
/// reference is released outside the main actor, cleanup waits for the main actor.
/// This module never requests Always authorization or enables background location updates.
@MainActor
public final class LocationManager {
  private let driver: any LocationDriver
  private let validateUsageDescription: () throws -> Void

  /// The most recently observed authorization status, updated before authorization callbacks.
  public private(set) var authorizationStatus: CLAuthorizationStatus
  /// Whether the user allows full or reduced accuracy, updated before authorization callbacks.
  ///
  /// Selecting ``LocationAccuracy/high`` does not override reduced-accuracy authorization.
  public private(set) var accuracyAuthorization: CLAccuracyAuthorization
  /// The most recent valid location reported by Core Location, or its initial cached location.
  ///
  /// This value can be stale. Check `timestamp` and `horizontalAccuracy` for your use case
  /// before attaching it to a photo or video. It remains available after stopping updates
  /// and becomes `nil` if authorization is revoked. Retaining a location keeps it alive
  /// independently of this manager.
  public private(set) var lastKnownLocation: CLLocation?
  /// Whether this manager has requested continuous updates and has not stopped them.
  ///
  /// A value of `true` does not guarantee a current GPS fix or uninterrupted updates.
  /// Core Location can pause updates automatically and suspend them in the background.
  public private(set) var isUpdating = false

  /// Receives the newest valid location in each Core Location update on the main actor.
  ///
  /// The callback runs only while ``isUpdating`` is `true`. The manager updates
  /// ``lastKnownLocation`` before calling it. Set this property to `nil` to remove it.
  public var onLocationChanged: ((CLLocation) -> Void)?
  /// Receives authorization and accuracy changes on the main actor, including the initial delegate event.
  ///
  /// After a grant, call ``startUpdating()`` explicitly if the feature still needs location.
  /// Revoking permission stops updates before this callback. Set this property to `nil` to remove it.
  public var onAuthorizationChanged: ((CLAuthorizationStatus, CLAccuracyAuthorization) -> Void)?
  /// Receives Core Location failures on the main actor while updates are active.
  ///
  /// A `CLError.locationUnknown` failure can be temporary, so updates remain active.
  /// A `CLError.denied` failure stops updates. Set this property to `nil` to remove it.
  public var onError: ((Error) -> Void)?

  /// Creates a foreground location manager without requesting permission or starting updates.
  ///
  /// - Parameter options: Desired accuracy and minimum movement between updates.
  /// - Throws: ``LocationManagerError/invalidDistanceFilter`` if the distance filter is invalid.
  public convenience init(options: LocationManagerOptions = .init()) throws {
    try options.validate()
    self.init(driver: CoreLocationDriver(options: options)) {
      try LocationUsageDescription.validate(in: .main)
    }
  }

  init(driver: any LocationDriver, validateUsageDescription: @escaping () throws -> Void) {
    self.driver = driver
    self.validateUsageDescription = validateUsageDescription
    authorizationStatus = driver.authorizationStatus
    accuracyAuthorization = driver.accuracyAuthorization
    if Self.isAuthorized(driver.authorizationStatus), let location = driver.location, location.horizontalAccuracy >= 0 {
      lastKnownLocation = location
    }
    driver.onLocations = { [weak self] locations in self?.receive(locations) }
    driver.onAuthorization = { [weak self] status, accuracy in self?.receive(status, accuracy: accuracy) }
    driver.onError = { [weak self] error in self?.receive(error) }
  }

  isolated deinit {
    driver.onLocations = nil
    driver.onAuthorization = nil
    driver.onError = nil
    if isUpdating { driver.stopUpdatingLocation() }
  }

  /// Asks the system for When In Use authorization if the current status is not determined.
  ///
  /// Call this in response to a user action while the app is in the foreground, after
  /// adding `NSLocationWhenInUseUsageDescription` to the app's `Info.plist`. The method
  /// returns immediately. Observe ``onAuthorizationChanged`` for the user's choice.
  /// Already determined authorization is left unchanged; denied permission must be changed in Settings.
  /// The system controls whether a prompt is shown. This method never starts location updates.
  ///
  /// - Throws: ``LocationManagerError/missingUsageDescription`` if the required purpose string is missing.
  public func requestWhenInUseAuthorization() throws {
    try validateUsageDescription()
    guard driver.authorizationStatus == .notDetermined else { return }
    driver.requestWhenInUseAuthorization()
  }

  /// Starts foreground location updates if authorization was already granted.
  ///
  /// Repeated calls while updating have no effect. This method throws for undetermined,
  /// denied, or restricted authorization and never requests permission implicitly.
  ///
  /// - Throws: ``LocationManagerError`` if authorization or the purpose string is missing.
  public func startUpdating() throws {
    let status = driver.authorizationStatus
    guard Self.isAuthorized(status) else { throw LocationManagerError.notAuthorized(status) }
    try validateUsageDescription()
    guard !isUpdating else { return }
    isUpdating = true
    driver.startUpdatingLocation()
  }

  /// Stops updates and suppresses any location or error events still queued for this manager.
  ///
  /// Repeated calls have no effect. Authorization changes remain observable, and
  /// ``lastKnownLocation`` remains available until authorization is revoked.
  public func stopUpdating() {
    guard isUpdating else { return }
    isUpdating = false
    driver.stopUpdatingLocation()
  }

  private static func isAuthorized(_ status: CLAuthorizationStatus) -> Bool {
    return status == .authorizedWhenInUse || status == .authorizedAlways
  }

  private func receive(_ locations: [CLLocation]) {
    guard isUpdating, let location = locations.last(where: { $0.horizontalAccuracy >= 0 }) else { return }
    lastKnownLocation = location
    onLocationChanged?(location)
  }

  private func receive(_ status: CLAuthorizationStatus, accuracy: CLAccuracyAuthorization) {
    authorizationStatus = status
    accuracyAuthorization = accuracy
    if !Self.isAuthorized(status) {
      stopUpdating()
      lastKnownLocation = nil
    }
    onAuthorizationChanged?(status, accuracy)
  }

  private func receive(_ error: Error) {
    guard isUpdating else { return }
    if let error = error as? CLError, error.code == .denied {
      stopUpdating()
      lastKnownLocation = nil
    }
    onError?(error)
  }
}
