// Copyright © 2025 Marc Rousavy @ Margelo
// Adapted from react-native-vision-camera-location. See OPTIONAL_MODULES.md.

import CoreLocation

/// Configuration for foreground location updates.
public struct LocationManagerOptions: Sendable {
  /// The desired accuracy of location updates. Defaults to ``LocationAccuracy/balanced``.
  public var accuracy: LocationAccuracy
  /// The minimum horizontal movement, in meters, before Core Location reports an update.
  ///
  /// Use a finite, nonnegative distance or `kCLDistanceFilterNone` to report all movement.
  /// Defaults to ten meters.
  public var distanceFilter: CLLocationDistance

  /// Creates location options without starting services or requesting permission.
  ///
  /// - Parameters:
  ///   - accuracy: The desired accuracy. Defaults to balanced.
  ///   - distanceFilter: The minimum movement in meters. Defaults to ten meters.
  public init(accuracy: LocationAccuracy = .balanced, distanceFilter: CLLocationDistance = 10) {
    self.accuracy = accuracy
    self.distanceFilter = distanceFilter
  }

  func validate() throws {
    guard distanceFilter.isFinite, distanceFilter >= 0 || distanceFilter == kCLDistanceFilterNone else {
      throw LocationManagerError.invalidDistanceFilter
    }
  }
}
