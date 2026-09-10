import CoreLocation
import Foundation

/// A configuration or authorization failure before location updates begin.
public enum LocationManagerError: Error, LocalizedError, Equatable {
  /// The distance filter is neither a finite, nonnegative distance nor `kCLDistanceFilterNone`.
  case invalidDistanceFilter
  /// The app has no nonempty `NSLocationWhenInUseUsageDescription` purpose string.
  case missingUsageDescription
  /// The app has not been granted location authorization.
  case notAuthorized(CLAuthorizationStatus)

  /// A description of the configuration or authorization failure.
  public var errorDescription: String? {
    switch self {
    case .invalidDistanceFilter:
      return "The location distance filter must be finite and nonnegative, or kCLDistanceFilterNone."
    case .missingUsageDescription:
      return "Add NSLocationWhenInUseUsageDescription to your app's Info.plist before requesting or using location."
    case .notAuthorized:
      return "Location permission has not been granted. Request When In Use authorization explicitly before starting updates."
    }
  }
}
