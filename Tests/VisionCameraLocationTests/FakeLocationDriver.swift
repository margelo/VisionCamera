import CoreLocation

@testable import VisionCameraLocation

@MainActor
final class FakeLocationDriver: LocationDriver {
  var authorizationStatus: CLAuthorizationStatus = .notDetermined
  var accuracyAuthorization: CLAccuracyAuthorization = .fullAccuracy
  var location: CLLocation?
  var onLocations: (([CLLocation]) -> Void)?
  var onAuthorization: ((CLAuthorizationStatus, CLAccuracyAuthorization) -> Void)?
  var onError: ((Error) -> Void)?
  var onStop: (() -> Void)?
  var onDeinit: (@Sendable () -> Void)?
  private(set) var authorizationRequests = 0
  private(set) var starts = 0
  private(set) var stops = 0

  func requestWhenInUseAuthorization() { authorizationRequests += 1 }
  func startUpdatingLocation() { starts += 1 }
  func stopUpdatingLocation() {
    stops += 1
    onStop?()
  }

  deinit { onDeinit?() }

  func sendAuthorization(_ status: CLAuthorizationStatus, accuracy: CLAccuracyAuthorization = .fullAccuracy) {
    authorizationStatus = status
    accuracyAuthorization = accuracy
    onAuthorization?(status, accuracy)
  }
}
