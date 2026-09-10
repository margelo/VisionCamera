import CoreLocation

@MainActor
protocol LocationDriver: AnyObject, Sendable {
  var authorizationStatus: CLAuthorizationStatus { get }
  var accuracyAuthorization: CLAccuracyAuthorization { get }
  var location: CLLocation? { get }
  var onLocations: (([CLLocation]) -> Void)? { get set }
  var onAuthorization: ((CLAuthorizationStatus, CLAccuracyAuthorization) -> Void)? { get set }
  var onError: ((Error) -> Void)? { get set }

  func requestWhenInUseAuthorization()
  func startUpdatingLocation()
  func stopUpdatingLocation()
}
