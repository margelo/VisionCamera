// Copyright © 2025 Marc Rousavy @ Margelo

import CoreVideo
import Foundation

/// A single plane of a planar ``Frame``.
///
/// The Plane independently retains its pixel buffer. Copying this value shares the native buffer
/// without copying pixels. Access the bytes through ``FramePlane/withUnsafeBytes(_:)``.
public struct FramePlane {
  /// The retained native pixel buffer containing this Plane.
  public let pixelBuffer: CVPixelBuffer
  /// The zero-based index of this Plane within the pixel buffer.
  public let index: Int

  /// Creates a Plane after validating the pixel buffer's layout and index.
  /// - Throws: If the buffer is not planar or the index is outside its available planes.
  public init(pixelBuffer: CVPixelBuffer, index: Int) throws(MediaError) {
    guard CVPixelBufferIsPlanar(pixelBuffer) else { throw .planeAccessRequiresPlanarBuffer }
    let planeCount = CVPixelBufferGetPlaneCount(pixelBuffer)
    guard (0..<planeCount).contains(index) else {
      throw .invalidPlaneIndex(index: index, planeCount: planeCount)
    }
    self.pixelBuffer = pixelBuffer
    self.index = index
  }

  /// The byte count of this Plane, including row padding.
  public var byteCount: Int { bytesPerRow * height }
  /// The Plane's width in pixels.
  public var width: Int { CVPixelBufferGetWidthOfPlane(pixelBuffer, index) }
  /// The Plane's height in pixels.
  public var height: Int { CVPixelBufferGetHeightOfPlane(pixelBuffer, index) }
  /// The row stride of this Plane, in bytes.
  public var bytesPerRow: Int { CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, index) }

  /// Provides scoped, read-only access to this Plane's bytes without copying them.
  ///
  /// The pixel buffer is locked throughout `body` and unlocked even when `body` throws. The pointer must
  /// not escape the closure. Copy it into `Data` to retain the bytes beyond the closure.
  /// - Throws: A ``MediaError`` if the Plane cannot be accessed, or the error thrown by `body`.
  public func withUnsafeBytes<Result>(_ body: (UnsafeRawBufferPointer) throws -> Result) throws -> Result {
    try pixelBuffer.withReadOnlyBytes(planeIndex: index, body)
  }
}
