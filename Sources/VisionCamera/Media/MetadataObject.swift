// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation

public final class MetadataObject: ScannedObject {
  public let object: AVMetadataObject

  public init(object: AVMetadataObject) { self.object = object }

  public var type: ScannedObjectType { ScannedObjectType(type: object.type) }
  public var boundingBox: BoundingBox { BoundingBox(object.bounds) }
}
