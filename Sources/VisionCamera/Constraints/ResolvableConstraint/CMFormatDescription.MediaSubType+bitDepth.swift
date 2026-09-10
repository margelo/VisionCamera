// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation

extension CMFormatDescription.MediaSubType {
  var bitDepth: DynamicRangeBitDepth {
    switch self {
    case .yuv4208BitVideo, .yuv4208BitFull, .yuv4228BitVideo, .yuv4228BitFull:
      return .sdr8Bit
    case .yuv42010BitVideo, .yuv42010BitFull, .yuv42210BitVideo, .yuv42210BitFull:
      return .hdr10Bit
    default:
      return .unknown
    }
  }
}
