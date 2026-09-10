// Copyright © 2025 Marc Rousavy @ Margelo
// Adapted from react-native-vision-camera-location. See OPTIONAL_MODULES.md.

import CoreLocation
import Foundation

@MainActor
final class CoreLocationDriver: NSObject, LocationDriver, @preconcurrency CLLocationManagerDelegate {
  private let manager: CLLocationManager
  var onLocations: (([CLLocation]) -> Void)?
  var onAuthorization: ((CLAuthorizationStatus, CLAccuracyAuthorization) -> Void)?
  var onError: ((Error) -> Void)?

  var authorizationStatus: CLAuthorizationStatus { manager.authorizationStatus }
  var accuracyAuthorization: CLAccuracyAuthorization { manager.accuracyAuthorization }
  var location: CLLocation? { manager.location }

  init(options: LocationManagerOptions) {
    manager = CLLocationManager()
    super.init()
    manager.delegate = self
    manager.desiredAccuracy = options.accuracy.nativeValue
    manager.distanceFilter = options.distanceFilter
    manager.pausesLocationUpdatesAutomatically = true
    manager.allowsBackgroundLocationUpdates = false
  }

  func requestWhenInUseAuthorization() { manager.requestWhenInUseAuthorization() }
  func startUpdatingLocation() { manager.startUpdatingLocation() }
  func stopUpdatingLocation() { manager.stopUpdatingLocation() }

  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    onLocations?(locations)
  }

  func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    onAuthorization?(manager.authorizationStatus, manager.accuracyAuthorization)
  }

  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    onError?(error)
  }
}
