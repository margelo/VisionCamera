// Copyright © 2025 Marc Rousavy @ Margelo

/// A constraint expressing a preference for Photo HDR.
///
/// The iOS constraint resolver ignores this preference. Smart HDR is managed by the capture pipeline.
public struct PhotoHDRConstraint: Equatable, Sendable {
  /// Whether to prefer photo HDR. This preference has no effect in the iOS resolver.
  public var photoHDR: Bool

  /// Creates a Photo HDR preference. The iOS resolver does not act on this preference.
  ///
  /// - Parameters:
  ///   - photoHDR: Whether to prefer photo HDR. This preference has no effect in the iOS resolver.
  public init(
    photoHDR: Bool
  ) {
    self.photoHDR = photoHDR
  }
}
