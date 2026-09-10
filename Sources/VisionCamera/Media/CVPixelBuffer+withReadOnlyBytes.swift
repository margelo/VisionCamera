// Copyright © 2025 Marc Rousavy @ Margelo

import CoreVideo
import Foundation

extension CVPixelBuffer {
  func withReadOnlyBytes<Result>(
    planeIndex: Int? = nil,
    _ body: (UnsafeRawBufferPointer) throws -> Result
  ) throws -> Result {
    if let planeIndex {
      guard CVPixelBufferIsPlanar(self) else { throw MediaError.planeAccessRequiresPlanarBuffer }
      let planeCount = CVPixelBufferGetPlaneCount(self)
      guard (0..<planeCount).contains(planeIndex) else {
        throw MediaError.invalidPlaneIndex(index: planeIndex, planeCount: planeCount)
      }
    } else if CVPixelBufferIsPlanar(self) {
      throw MediaError.nonPlanarPixelBufferRequired
    }

    let status = CVPixelBufferLockBaseAddress(self, .readOnly)
    guard status == kCVReturnSuccess else {
      throw MediaError.pixelBufferLockFailed(status: status)
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
      throw MediaError.pixelBufferBaseAddressUnavailable
    }
    return try withExtendedLifetime(self) {
      try body(UnsafeRawBufferPointer(start: address, count: count))
    }
  }
}
