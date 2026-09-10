// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation

/// Represents any kind of scanned object.
/// See ``ScannedCode``
/// See ``ScannedFace``
public protocol ScannedObject: AnyObject {
  /// The underlying `AVMetadataObject`, retained by this scanned object.
  var object: AVMetadataObject { get }
  /// The ``ScannedObjectType`` of this ``ScannedObject``.
  var type: ScannedObjectType { get }
  /// The bounding box coordinates of this ``ScannedObject``.
  ///
  /// Objects delivered by ``CameraObjectOutput`` use camera-space coordinates (`0.0` ... `1.0`). Objects
  /// converted by ``PreviewView`` use the preview view's coordinate system.
  var boundingBox: BoundingBox { get }
}
