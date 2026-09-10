// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation
import CoreGraphics

/// A machine-readable code, such as a QR code.
public struct ScannedCode: ScannedObject {
  /// The retained native machine-readable code object.
  public let code: AVMetadataMachineReadableCodeObject
  /// The underlying AVFoundation metadata object.
  public var object: AVMetadataObject { code }

  /// Creates a value retaining a native scanned code.
  public init(object: AVMetadataMachineReadableCodeObject) { self.code = object }

  /// The native metadata type, including types introduced by newer Apple SDKs.
  public var type: AVMetadataObject.ObjectType { code.type }
  /// The bounding box coordinates of this ``ScannedObject``.
  ///
  /// ``ObjectOutput`` delivers normalized Camera coordinates. Values converted through ``PreviewView``
  /// use the preview view's coordinate system instead.
  public var bounds: CGRect { code.bounds }
  /// The decoded, error-corrected value, or `nil` if the code cannot be decoded.
  public var value: String? { code.stringValue }
  /// The corner points outlining the code, in the same coordinate system as ``ScannedCode/bounds``.
  public var corners: [CGPoint] { code.corners }
}
