// Copyright © 2025 Marc Rousavy @ Margelo
// Adapted from react-native-vision-camera-location. See OPTIONAL_MODULES.md.

import CoreLocation

/// The accuracy requested from Core Location.
///
/// These values describe desired accuracy. The device, environment, and the user's
/// precise-location setting determine the accuracy of each returned location.
public enum LocationAccuracy: Sendable, CaseIterable {
  /// Requests Core Location's best available accuracy.
  case high
  /// Requests accuracy within ten meters.
  case balanced
  /// Requests accuracy within one hundred meters.
  case low

  var nativeValue: CLLocationAccuracy {
    switch self {
    case .high: return kCLLocationAccuracyBest
    case .balanced: return kCLLocationAccuracyNearestTenMeters
    case .low: return kCLLocationAccuracyHundredMeters
    }
  }
}
