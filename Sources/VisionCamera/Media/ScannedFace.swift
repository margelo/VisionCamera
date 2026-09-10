// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation
import CoreGraphics

/// A face detected by the capture pipeline.
public struct ScannedFace: ScannedObject, Identifiable {
  /// The retained native face metadata.
  public let face: AVMetadataFaceObject
  /// The underlying AVFoundation metadata object.
  public var object: AVMetadataObject { face }

  /// Creates a value retaining a native detected face.
  public init(object: AVMetadataFaceObject) { self.face = object }

  /// The detected metadata object type.
  public var type: AVMetadataObject.ObjectType { face.type }
  /// The face's bounds in its current coordinate system.
  ///
  /// ``ObjectOutput`` delivers normalized Camera coordinates. Values converted through ``PreviewView``
  /// use the preview view's coordinate system instead.
  public var bounds: CGRect { face.bounds }
  /// The capture pipeline's identifier for tracking this face within a scene.
  public var id: Int { face.faceID }
  /// The face's roll angle in degrees, or `nil` when AVFoundation has no roll estimate.
  public var rollAngle: CGFloat? { face.hasRollAngle ? face.rollAngle : nil }
  /// The face's yaw angle in degrees, or `nil` when AVFoundation has no yaw estimate.
  public var yawAngle: CGFloat? { face.hasYawAngle ? face.yawAngle : nil }
}
