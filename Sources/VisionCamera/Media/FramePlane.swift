// Copyright © 2025 Marc Rousavy @ Margelo

import CoreVideo
import Foundation

/// An independently retained plane of a planar pixel buffer.
public final class FramePlane {
  public private(set) var pixelBuffer: CVPixelBuffer?
  public let planeIndex: Int

  public init(buffer: CVPixelBuffer, planeIndex: Int) throws {
    guard CVPixelBufferIsPlanar(buffer),
      planeIndex >= 0,
      planeIndex < CVPixelBufferGetPlaneCount(buffer)
    else {
      throw CameraError(message: "Pixel buffer plane index \(planeIndex) is out of bounds.")
    }
    self.pixelBuffer = buffer
    self.planeIndex = planeIndex
  }

  public var memorySize: Int { pixelBuffer?.memorySize(ofPlaneIndex: planeIndex) ?? 0 }
  public var width: Double { pixelBuffer.map { Double(CVPixelBufferGetWidthOfPlane($0, planeIndex)) } ?? 0 }
  public var height: Double { pixelBuffer.map { Double(CVPixelBufferGetHeightOfPlane($0, planeIndex)) } ?? 0 }
  public var bytesPerRow: Double { pixelBuffer.map { Double(CVPixelBufferGetBytesPerRowOfPlane($0, planeIndex)) } ?? 0 }
  public var isValid: Bool { pixelBuffer != nil }

  public func dispose() { pixelBuffer = nil }

  public func getPixelBuffer() throws -> CVPixelBuffer {
    guard let pixelBuffer else { throw CameraError(message: "This frame plane has been disposed.") }
    return pixelBuffer
  }

  /// The pointer is valid only during `body`. Copy its bytes to retain them afterward.
  public func withUnsafeBytes<Result>(_ body: (UnsafeRawBufferPointer) throws -> Result) throws -> Result {
    let pixelBuffer = try getPixelBuffer()
    return try pixelBuffer.withReadOnlyBytes(planeIndex: planeIndex, body)
  }
}
