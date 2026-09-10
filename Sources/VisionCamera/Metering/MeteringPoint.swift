// Copyright © 2025 Marc Rousavy @ Margelo

import CoreGraphics

/// A point for focusing AE/AF/AWB on the Camera via ``CameraController``.
///
/// Create a point from a ``PreviewView`` with ``PreviewView/meteringPoint(at:size:)``,
/// or supply normalized Camera coordinates directly.
///
/// ```swift
/// let point = MeteringPoint(location: CGPoint(x: 0.5, y: 0.5))
/// try await controller.focus(at: point)
/// ```
public struct MeteringPoint: Equatable, Sendable {
  /// The location in normalized Camera coordinates, ranging from `0.0` to `1.0` on each axis.
  public let location: CGPoint
  /// The normalized radius of the metering region. AVFoundation uses the location as its point of interest.
  public let size: CGFloat

  /// Creates a metering point in normalized Camera coordinates.
  ///
  /// You are responsible for handling orientation, cropping, and scaling. For view coordinates,
  /// use ``PreviewView/meteringPoint(at:size:)``.
  /// - Parameters:
  ///   - location: The location in the Camera's normalized coordinate system.
  ///   - size: The normalized radius, defaulting to `0.1`.
  public init(location: CGPoint, size: CGFloat = 0.1) {
    self.location = location
    self.size = size
  }
}
