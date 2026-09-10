// Copyright © 2025 Marc Rousavy @ Margelo

import CoreVideo
import Foundation

/// Represents a single Plane of a **planar** ``Frame``.
///
/// Each Plane retains the parent pixel buffer independently. Disposing its parent Frame does not invalidate the Plane.
/// See ``Frame/getPlanes()``.
public final class FramePlane {
  /// The retained native pixel buffer, or `nil` after disposal. A separately retained buffer remains valid independently of this instance.
  public private(set) var pixelBuffer: CVPixelBuffer?
  /// The zero-based index of this Plane in its pixel buffer.
  public let planeIndex: Int

  /// Creates a Plane that retains the given pixel buffer independently of its parent Frame.
  ///
  /// - Parameter buffer: A planar pixel buffer.
  /// - Parameter planeIndex: The zero-based plane index.
  /// - Throws: If the buffer is not planar or the index is outside its plane bounds.
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

  /// The byte count of this Plane, including row padding, or `0` after disposal.
  public var memorySize: Int { pixelBuffer?.memorySize(ofPlaneIndex: planeIndex) ?? 0 }
  /// Returns the width of this Plane.
  ///
  /// - Note: If this Plane is invalid (``FramePlane/isValid``),
  /// this just returns `0`.
  public var width: Double { pixelBuffer.map { Double(CVPixelBufferGetWidthOfPlane($0, planeIndex)) } ?? 0 }
  /// Returns the height of this Plane.
  ///
  /// - Note: If this Plane is invalid (``FramePlane/isValid``),
  /// this just returns `0`.
  public var height: Double { pixelBuffer.map { Double(CVPixelBufferGetHeightOfPlane($0, planeIndex)) } ?? 0 }
  /// Get the number of bytes per row of the
  /// underlying pixel buffer.
  ///
  /// See ``FramePlane/width``
  /// See ``FramePlane/getPixelBuffer()``
  public var bytesPerRow: Double { pixelBuffer.map { Double(CVPixelBufferGetBytesPerRowOfPlane($0, planeIndex)) } ?? 0 }
  /// Whether this Plane still retains its pixel buffer. Disposing the parent Frame does not invalidate this Plane.
  public var isValid: Bool { pixelBuffer != nil }

  /// Releases this instance's reference to its native buffer early.
  ///
  /// Repeated calls have no effect. Buffers and Planes retained separately remain valid. ARC also releases the reference when this instance is deallocated.
  public func dispose() { pixelBuffer = nil }

  /// Returns the retained native `CVPixelBuffer` without copying its pixels.
  ///
  /// The returned buffer remains valid after this instance is disposed while the caller retains it.
  /// - Throws: If this instance has been disposed or has no pixel buffer.
  public func getPixelBuffer() throws -> CVPixelBuffer {
    guard let pixelBuffer else { throw CameraError(message: "This frame plane has been disposed.") }
    return pixelBuffer
  }

  /// Provides scoped, read-only access to the Plane's bytes without copying them.
  ///
  /// The buffer is locked for the duration of `body` and unlocked even if `body` throws. The pointer must not escape the closure. Copy the bytes into `Data` to keep them beyond the closure.
  ///
  /// - Throws: If the buffer is unavailable, the Plane cannot be accessed, locking fails, or `body` throws.
  public func withUnsafeBytes<Result>(_ body: (UnsafeRawBufferPointer) throws -> Result) throws -> Result {
    let pixelBuffer = try getPixelBuffer()
    return try pixelBuffer.withReadOnlyBytes(planeIndex: planeIndex, body)
  }
}
