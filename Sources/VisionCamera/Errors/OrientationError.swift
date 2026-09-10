// Copyright © 2025 Marc Rousavy @ Margelo

import Foundation

/// A device orientation source that is unavailable.
public enum OrientationError: Error, LocalizedError {
  /// This device has no accelerometer available for orientation updates.
  case accelerometerUnavailable

  /// A description of the unavailable orientation source.
  public var errorDescription: String? {
    switch self {
    case .accelerometerUnavailable: return "Device orientation updates require an accelerometer."
    }
  }
}
