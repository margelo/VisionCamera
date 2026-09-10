// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation

/// Represents any kind of scanned object.
/// See ``ScannedCode``
/// See ``ScannedFace``
public protocol ScannedObject {
  /// The underlying `AVMetadataObject`, retained by this scanned object.
  var object: AVMetadataObject { get }
  /// The native AVFoundation metadata type.
  var type: AVMetadataObject.ObjectType { get }
  /// The bounding box coordinates of this ``ScannedObject``.
  ///
  /// Objects delivered by ``ObjectOutput`` use camera-space coordinates (`0.0` ... `1.0`). Objects
  /// converted by ``PreviewView`` use the preview view's coordinate system.
  var bounds: CGRect { get }
}
