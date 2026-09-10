// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation

public final class ScannedFace: ScannedObject {
  public let face: AVMetadataFaceObject
  public var object: AVMetadataObject { face }

  public init(object: AVMetadataFaceObject) { self.face = object }

  public var type: ScannedObjectType { ScannedObjectType(type: face.type) }
  public var boundingBox: BoundingBox { BoundingBox(face.bounds) }
  public var faceID: Double { Double(face.faceID) }
  public var hasRollAngle: Bool { face.hasRollAngle }
  public var rollAngle: Double { Double(face.rollAngle) }
  public var hasYawAngle: Bool { face.hasYawAngle }
  public var yawAngle: Double { Double(face.yawAngle) }
}
