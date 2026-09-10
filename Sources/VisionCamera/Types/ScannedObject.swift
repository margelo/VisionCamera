// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation

public protocol ScannedObject: AnyObject {
  var object: AVMetadataObject { get }
  var type: ScannedObjectType { get }
  var boundingBox: BoundingBox { get }
}
