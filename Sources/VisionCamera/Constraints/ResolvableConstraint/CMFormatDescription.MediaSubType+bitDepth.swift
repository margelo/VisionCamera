// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation

extension CMFormatDescription.MediaSubType {
  var bitDepth: DynamicRangeBitDepth {
    switch self {
    case .yuv4208BitVideo, .yuv4208BitFull, .yuv4228BitVideo, .yuv4228BitFull, .yuv4448BitVideo, .yuv4448BitFull, .rgbBgra8Bit, .rgbRgba8Bit, .rgbRgb8Bit:
      return .bit8
    case .yuv42010BitVideo, .yuv42010BitFull, .yuv42210BitVideo, .yuv42210BitFull:
      return .bit10
    default:
      return .unknown
    }
  }
}
