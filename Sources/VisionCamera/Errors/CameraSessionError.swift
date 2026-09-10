// Copyright © 2025 Marc Rousavy @ Margelo

import Foundation

/// An unexpected Camera Session notification that does not include an underlying Apple error.
///
/// When AVFoundation supplies an error, the session passes that original error to its observers.
public enum CameraSessionError: Error, LocalizedError {
  /// AVFoundation reported a runtime error without an error payload.
  case missingRuntimeError

  /// A description of the missing runtime error payload.
  public var errorDescription: String? {
    return "AVFoundation reported a Camera Session error without an underlying error."
  }
}
