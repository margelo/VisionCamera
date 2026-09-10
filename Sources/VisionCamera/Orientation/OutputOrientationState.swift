// Copyright © 2025 Marc Rousavy @ Margelo

import CoreMedia
import Foundation

/// Shares the output's requested transform between its own delegate and a data synchronizer.
final class OutputOrientationState {
  // Normal delivery and synchronized delivery run on different queues. Only these two mutable values
  // cross that boundary; snapshot them together, then release the lock before converting a sample.
  private let lock = NSLock()
  private var orientation: CameraOrientation = .up
  private var mirrorMode: MirrorMode = .auto

  func setOrientation(_ orientation: CameraOrientation) {
    lock.lock()
    self.orientation = orientation
    lock.unlock()
  }

  func setMirrorMode(_ mirrorMode: MirrorMode) {
    lock.lock()
    self.mirrorMode = mirrorMode
    lock.unlock()
  }

  func metadata(at timestamp: CMTime, bufferOrientation: CameraOrientation, isBufferMirrored: Bool) -> MediaSampleMetadata {
    lock.lock()
    let orientation = self.orientation
    let mirrorMode = self.mirrorMode
    lock.unlock()

    let isMirrored: Bool
    switch mirrorMode {
    case .auto:
      isMirrored = false
    case .on:
      isMirrored = !isBufferMirrored
    case .off:
      isMirrored = isBufferMirrored
    }
    return MediaSampleMetadata(
      timestamp: timestamp,
      orientation: bufferOrientation.relativeTo(orientation),
      isMirrored: isMirrored)
  }
}
