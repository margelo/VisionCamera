// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation

/// Represents a machine-readable code, such as a QR code.
public final class ScannedCode: ScannedObject {
  /// The retained native AVFoundation metadata object.
  public let code: AVMetadataMachineReadableCodeObject
  /// The underlying AVFoundation metadata object.
  public var object: AVMetadataObject { code }

  /// Creates a ScannedCode that retains the given native AVFoundation metadata object.
  public init(object: AVMetadataMachineReadableCodeObject) { self.code = object }

  /// The ``ScannedObjectType`` of this ``ScannedObject``.
  public var type: ScannedObjectType { ScannedObjectType(type: code.type) }
  /// The bounding box coordinates of this ``ScannedObject``.
  ///
  /// Coordinates are in camera-space (`0.0` ... `1.0`), and can be
  /// converted to view-space via the ``PreviewView``.
  public var boundingBox: BoundingBox { BoundingBox(code.bounds) }
  /// The decoded string value of this ``ScannedCode``, or `nil`
  /// if the value cannot be decoded.
  /// This is error-corrected.
  public var value: String? { code.stringValue }
  /// The corner points outlining this ``ScannedCode``.
  ///
  /// Coordinates are in camera-space (`0.0` ... `1.0`), and can be
  /// converted to view-space via the ``PreviewView``.
  public var cornerPoints: [Point] { code.corners.map { Point($0) } }
}
