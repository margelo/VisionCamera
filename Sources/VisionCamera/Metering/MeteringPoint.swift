///
/// MeteringPoint.swift
/// VisionCamera
/// Copyright © 2025 Marc Rousavy @ Margelo
///

import AVFoundation
import CoreGraphics
import Foundation

/// Represents a point that can be used for focusing AE/AF/AWB
/// on the Camera via ``CameraController``.
///
/// You can create a ``MeteringPoint`` via a ``PreviewView``'s
/// `ref` (see ``PreviewView/createMeteringPoint(viewX:viewY:size:)``), or manually
/// via ``VisionCamera/createNormalizedMeteringPoint(x:y:size:)``.
///
/// ```swift
/// let point = VisionCamera().createNormalizedMeteringPoint(x: 0.5, y: 0.5)
/// try await controller.focusTo(point: point, options: .init())
///
/// let tappedPoint = try previewView.createMeteringPoint(viewX: tapX, viewY: tapY)
/// try await controller.focusTo(point: tappedPoint, options: .init())
/// ```
public final class MeteringPoint {
  /// Represents the X coordinate of this ``MeteringPoint``,
  /// relative to whatever source was used to create this point.
  ///
  /// - If created from a ``PreviewView``, this will be the
  /// given View X coordinate (e.g. of the user tap).
  /// - If created from a normalized Point (``VisionCamera/createNormalizedMeteringPoint(x:y:size:)``),
  /// this will be the given normalized X coordinate (0...1)
  public var relativeX: Double
  /// Represents the Y coordinate of this ``MeteringPoint``,
  /// relative to whatever source was used to create this point.
  ///
  /// - If created from a ``PreviewView``, this will be the
  /// given View Y coordinate (e.g. of the user tap).
  /// - If created from a normalized Point (``VisionCamera/createNormalizedMeteringPoint(x:y:size:)``),
  /// this will be the given normalized Y coordinate (0...1)
  public var relativeY: Double
  /// Represents the size/radius of this ``MeteringPoint``,
  /// relative to whatever source was used to create this point - or
  /// `nil` if no relative size was set.
  public var relativeSize: Double?

  /// Represents the X coordinate of this ``MeteringPoint``,
  /// normalized to the Camera's coordinate system after applying
  /// orientation, cropping, and scaling.
  public var normalizedX: Double
  /// Represents the Y coordinate of this ``MeteringPoint``,
  /// normalized to the Camera's coordinate system after applying
  /// orientation, cropping, and scaling.
  public var normalizedY: Double
  /// Represents the size of this ``MeteringPoint``,
  /// normalized to the Camera's coordinate system after applying
  /// orientation, cropping, and scaling.
  public var normalizedSize: Double

  /// Creates a Metering Point from normalized Camera coordinates and a normalized size.
  public init(normalizedX: Double, normalizedY: Double, normalizedSize: Double) {
    self.relativeX = normalizedX
    self.relativeY = normalizedY
    self.relativeSize = normalizedSize
    self.normalizedX = normalizedX
    self.normalizedY = normalizedY
    self.normalizedSize = normalizedSize
  }
  /// Creates a Metering Point with both relative view coordinates and normalized Camera coordinates. An omitted relative size uses a normalized size of `0.1`.
  public init(
    relativeX: Double, relativeY: Double, relativeSize: Double?, normalizedX: Double,
    normalizedY: Double
  ) {
    self.relativeX = relativeX
    self.relativeY = relativeY
    self.relativeSize = relativeSize
    self.normalizedX = normalizedX
    self.normalizedY = normalizedY

    if let relativeSize {
      let fullX = relativeX / normalizedX
      self.normalizedSize = relativeSize / fullX
    } else {
      self.normalizedSize = 0.1
    }
  }

  /// Returns this Metering Point's normalized Camera coordinates as a `CGPoint`.
  public func toNormalizedPoint() -> CGPoint {
    return CGPoint(x: normalizedX, y: normalizedY)
  }
}
