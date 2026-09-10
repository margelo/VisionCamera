// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation
import CoreGraphics

/// A scanned metadata object without a more specific code or face representation.
public struct MetadataObject: ScannedObject {
  /// The retained native AVFoundation metadata object.
  public let object: AVMetadataObject

  /// Creates a value retaining a native metadata object.
  public init(object: AVMetadataObject) { self.object = object }

  /// The native metadata type, including types introduced by newer Apple SDKs.
  public var type: AVMetadataObject.ObjectType { object.type }
  /// The bounding box coordinates of this ``ScannedObject``.
  ///
  /// ``ObjectOutput`` delivers normalized Camera coordinates. Values converted through ``PreviewView``
  /// use the preview view's coordinate system instead.
  public var bounds: CGRect { object.bounds }
}
