// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation

extension CMFormatDescription.MediaSubType {
  var colorRange: ColorRange {
    switch self {
    case .yuv4208BitVideo, .yuv42010BitVideo, .yuv4228BitVideo, .yuv42210BitVideo:
      return .video
    case .yuv4208BitFull, .yuv42010BitFull, .yuv4228BitFull, .yuv42210BitFull:
      return .full
    default:
      return .unknown
    }
  }
}
