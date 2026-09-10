// Copyright © 2025 Marc Rousavy @ Margelo

import CoreGraphics

/// A normalized capture-device point of interest for automatic focus and exposure.
///
/// Coordinates range from `0` to `1`, with `(0, 0)` at the top-left of the unrotated image.
/// White balance uses the whole scene and does not consume this point.
/// Use ``PreviewView/meteringPoint(at:)`` to account for preview orientation, scaling, and cropping.
public struct MeteringPoint: Equatable, Sendable {
  /// The location in normalized capture-device coordinates, with each axis in `0...1`.
  public let location: CGPoint

  /// Creates a point whose finite coordinates must lie within `0...1` when focusing.
  public init(location: CGPoint) {
    self.location = location
  }
}
