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

  /// The detected code format.
  public var type: ScannedObjectType { ScannedObjectType(type: code.type) }
  /// The code's bounds in its current coordinate system.
  ///
  /// ``ObjectOutput`` delivers normalized Camera coordinates. Values converted through ``PreviewView``
  /// use the preview view's coordinate system instead.
  public var bounds: CGRect { code.bounds }
  /// The decoded, error-corrected value, or `nil` if the code cannot be decoded.
  public var value: String? { code.stringValue }
  /// The corner points outlining the code, in the same coordinate system as ``ScannedCode/bounds``.
  public var corners: [CGPoint] { code.corners }
}
