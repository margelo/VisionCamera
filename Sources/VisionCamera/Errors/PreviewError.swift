// Copyright © 2025 Marc Rousavy @ Margelo

import CoreGraphics
import Foundation

/// A preview coordinate conversion that cannot be completed.
public enum PreviewError: Error, LocalizedError {
  /// The view has no attached preview output.
  case outputNotAttached
  /// AVFoundation could not transform the scanned object's coordinates.
  case metadataConversionFailed
  /// A metering radius must be finite and nonnegative.
  case invalidMeteringRadius(CGFloat)

  /// A description of the failed conversion.
  public var errorDescription: String? {
    switch self {
    case .outputNotAttached: return "The Preview View has no attached output."
    case .metadataConversionFailed: return "Cannot convert this scanned object into preview coordinates."
    case .invalidMeteringRadius(let radius): return "The metering radius must be finite and nonnegative. Received \(radius)."
    }
  }
}
