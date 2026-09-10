// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation
import CoreGraphics

/// A scanned metadata object without a more specific code or face representation.
public struct MetadataObject: ScannedObject {
  /// The retained native AVFoundation metadata object.
  public let object: AVMetadataObject

  /// Creates a value retaining a native metadata object.
  public init(object: AVMetadataObject) { self.object = object }

  /// The type of object detected by the capture pipeline.
  public var type: ScannedObjectType { ScannedObjectType(type: object.type) }
  /// The object's bounds in its current coordinate system.
  ///
  /// ``ObjectOutput`` delivers normalized Camera coordinates. Values converted through ``PreviewView``
  /// use the preview view's coordinate system instead.
  public var bounds: CGRect { object.bounds }
}
