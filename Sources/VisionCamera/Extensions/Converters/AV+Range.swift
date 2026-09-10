///
/// CameraRange+toAVFrameRateRange.swift
/// VisionCamera
/// Copyright © 2025 Marc Rousavy @ Margelo
///

import AVFoundation
import Foundation

extension CameraRange {
  init(range: AVFrameRateRange) {
    self.init(min: range.minFrameRate, max: range.maxFrameRate)
  }
}
