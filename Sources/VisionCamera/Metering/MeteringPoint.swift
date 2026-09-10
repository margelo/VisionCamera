///
/// MeteringPoint.swift
/// VisionCamera
/// Copyright © 2025 Marc Rousavy @ Margelo
///

import CoreGraphics

/// A normalized capture-device point of interest for automatic focus and exposure.
///
/// Coordinates range from `0` to `1`, with `(0, 0)` at the top-left of the unrotated image.
/// White balance uses the whole scene and does not consume this point.
/// Use ``PreviewView/meteringPoint(at:)`` to account for the preview's orientation, scaling, and cropping.
///
/// ```swift
/// let point = MeteringPoint(normalizedX: 0.5, normalizedY: 0.5)
/// try await controller.focusTo(point: point)
/// ```
public struct MeteringPoint: Equatable, Sendable {
  /// The horizontal coordinate in the capture device's normalized coordinate system.
  public let normalizedX: Double
  /// The vertical coordinate in the capture device's normalized coordinate system.
  public let normalizedY: Double

  /// Creates a point in the capture device's normalized coordinate system.
  ///
  /// Both coordinates must be finite and within `0...1` when passed to ``CameraController/focusTo(point:options:)``.
  public init(normalizedX: Double, normalizedY: Double) {
    self.normalizedX = normalizedX
    self.normalizedY = normalizedY
  }

  /// Returns the normalized capture-device point as a `CGPoint`.
  public func toNormalizedPoint() -> CGPoint {
    return CGPoint(x: normalizedX, y: normalizedY)
  }
}
