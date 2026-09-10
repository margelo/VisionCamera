// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation

/// Represents a Face.
public final class ScannedFace: ScannedObject {
  /// The retained native AVFoundation metadata object.
  public let face: AVMetadataFaceObject
  /// The underlying AVFoundation metadata object.
  public var object: AVMetadataObject { face }

  /// Creates a ScannedFace that retains the given native AVFoundation metadata object.
  public init(object: AVMetadataFaceObject) { self.face = object }

  /// The ``ScannedObjectType`` of this ``ScannedObject``.
  public var type: ScannedObjectType { ScannedObjectType(type: face.type) }
  /// The bounding box coordinates of this ``ScannedObject``.
  ///
  /// Coordinates are in camera-space (`0.0` ... `1.0`), and can be
  /// converted to view-space via the ``PreviewView``.
  public var boundingBox: BoundingBox { BoundingBox(face.bounds) }
  /// The ID of this ``ScannedFace`` used to
  /// identify multiple faces in the same scene.
  public var faceID: Double { Double(face.faceID) }
  /// A Boolean value indicating whether there is a valid roll angle associated with the face.
  public var hasRollAngle: Bool { face.hasRollAngle }
  /// The roll angle of the face specified in degrees.
  public var rollAngle: Double { Double(face.rollAngle) }
  /// A Boolean value indicating whether there is a valid yaw angle associated with the face.
  public var hasYawAngle: Bool { face.hasYawAngle }
  /// The yaw angle of the face specified in degrees.
  public var yawAngle: Double { Double(face.yawAngle) }
}
