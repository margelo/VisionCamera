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

  /// The native metadata type, including types introduced by newer Apple SDKs.
  public var type: AVMetadataObject.ObjectType { face.type }
  /// The bounding box coordinates of this ``ScannedObject``.
  ///
  /// Coordinates are in camera-space (`0.0` ... `1.0`), and can be
  /// converted to view-space via the ``PreviewView``.
  public var boundingBox: BoundingBox { BoundingBox(face.bounds) }
  /// The ID of this ``ScannedFace`` used to
  /// identify multiple faces in the same scene.
  public var faceID: Int { face.faceID }
  /// The roll angle in degrees, or `nil` when AVFoundation has no valid roll angle.
  public var rollAngle: CGFloat? { face.hasRollAngle ? face.rollAngle : nil }
  /// The yaw angle in degrees, or `nil` when AVFoundation has no valid yaw angle.
  public var yawAngle: CGFloat? { face.hasYawAngle ? face.yawAngle : nil }
}
