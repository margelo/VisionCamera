// Copyright © 2025 Marc Rousavy @ Margelo

/// Represents the bounding box around a ``ScannedObject``.
///
/// For objects delivered by ``CameraObjectOutput``, coordinates are in camera-space (`0.0` ... `1.0`). After
/// conversion with ``PreviewView/convertScannedObjectCoordinatesToViewCoordinates(scannedObject:)``,
/// coordinates are in the preview view's coordinate system.
public struct BoundingBox: Equatable, Sendable {
  /// The minimum X coordinate.
  public var x: Double
  /// The minimum Y coordinate.
  public var y: Double
  /// The width of the bounding box.
  public var width: Double
  /// The height of the bounding box.
  public var height: Double

  /// Creates a bounding box from its origin and dimensions.
  ///
  /// - Parameters:
  ///   - x: The minimum X coordinate.
  ///   - y: The minimum Y coordinate.
  ///   - width: The width of the bounding box.
  ///   - height: The height of the bounding box.
  public init(
    x: Double,
    y: Double,
    width: Double,
    height: Double
  ) {
    self.x = x
    self.y = y
    self.width = width
    self.height = height
  }
}
