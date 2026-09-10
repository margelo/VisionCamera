// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation

public final class ScannedCode: ScannedObject {
  public let code: AVMetadataMachineReadableCodeObject
  public var object: AVMetadataObject { code }

  public init(object: AVMetadataMachineReadableCodeObject) { self.code = object }

  public var type: ScannedObjectType { ScannedObjectType(type: code.type) }
  public var boundingBox: BoundingBox { BoundingBox(code.bounds) }
  public var value: String? { code.stringValue }
  public var cornerPoints: [Point] { code.corners.map { Point($0) } }
}
