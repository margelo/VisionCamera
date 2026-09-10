// Copyright © 2025 Marc Rousavy @ Margelo

/// A constraint to prefer a binned format, or prefer a non-binned format.
///
/// Pixel binning combines multiple neighboring sensor pixels into one larger effective pixel.
/// This usually improves low-light sensitivity and reduces noise, but can trade away fine detail
/// compared to a full-resolution non-binned readout.
/// Additionally, binned formats are more performant as they use significantly less bandwidth.
///
/// ```swift
/// BinnedConstraint(binned: true)
/// ```
public struct BinnedConstraint: Equatable, Sendable {
  /// Whether to prefer pixel binning. Set this to `false` to prefer full-resolution sensor readout.
  public var binned: Bool

  /// Creates a preference for binned or non-binned sensor readout.
  ///
  /// - Parameters:
  ///   - binned: Whether to prefer pixel binning. Set this to `false` to prefer full-resolution sensor readout.
  public init(
    binned: Bool
  ) {
    self.binned = binned
  }
}
