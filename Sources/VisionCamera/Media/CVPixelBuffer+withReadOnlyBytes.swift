// Copyright © 2025 Marc Rousavy @ Margelo

import CoreVideo
import Foundation

extension CVPixelBuffer {
  func withReadOnlyBytes<Result>(
    planeIndex: Int? = nil,
    _ body: (UnsafeRawBufferPointer) throws -> Result
  ) throws -> Result {
    if let planeIndex {
      guard CVPixelBufferIsPlanar(self),
        planeIndex >= 0,
        planeIndex < CVPixelBufferGetPlaneCount(self)
      else {
        throw CameraError(message: "Pixel buffer plane index \(planeIndex) is out of bounds.")
      }
    } else if CVPixelBufferIsPlanar(self) {
      throw CameraError(message: "Use individual planes to access a planar pixel buffer's bytes.")
    }

    let status = CVPixelBufferLockBaseAddress(self, .readOnly)
    guard status == kCVReturnSuccess else {
      throw CameraError(message: "Could not lock pixel buffer for reading (status \(status)).")
    }
    defer { CVPixelBufferUnlockBaseAddress(self, .readOnly) }

    let address: UnsafeMutableRawPointer?
    let count: Int
    if let planeIndex {
      address = CVPixelBufferGetBaseAddressOfPlane(self, planeIndex)
      count =
        CVPixelBufferGetBytesPerRowOfPlane(self, planeIndex)
        * CVPixelBufferGetHeightOfPlane(self, planeIndex)
    } else {
      address = CVPixelBufferGetBaseAddress(self)
      count = CVPixelBufferGetBytesPerRow(self) * CVPixelBufferGetHeight(self)
    }
    guard let address else {
      throw CameraError(message: "Pixel buffer does not have a CPU-accessible base address.")
    }
    return try withExtendedLifetime(self) {
      try body(UnsafeRawBufferPointer(start: address, count: count))
    }
  }
}
