// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation

/// Represents any kind of scanned object.
/// See ``ScannedCode``
/// See ``ScannedFace``
public final class MetadataObject: ScannedObject {
  /// The retained native AVFoundation metadata object.
  public let object: AVMetadataObject

  /// Creates a MetadataObject that retains the given native AVFoundation metadata object.
  public init(object: AVMetadataObject) { self.object = object }

  /// The ``ScannedObjectType`` of this ``ScannedObject``.
  public var type: ScannedObjectType { ScannedObjectType(type: object.type) }
  /// The bounding box coordinates of this ``ScannedObject``.
  ///
  /// Coordinates are in camera-space (`0.0` ... `1.0`), and can be
  /// converted to view-space via the ``PreviewView``.
  public var boundingBox: BoundingBox { BoundingBox(object.bounds) }
}
