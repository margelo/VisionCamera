// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation

extension TargetPhotoContainerFormat {
  func captureSettings(for output: AVCapturePhotoOutput) throws -> AVCapturePhotoSettings {
    if self == .dng {
      guard let rawFormat = output.bestRawPixelFormat else {
        throw CaptureError.rawCaptureUnsupported
      }
      return AVCapturePhotoSettings(rawPixelFormatType: rawFormat)
    }
    let format = try processedFormat(availableCodecs: output.availablePhotoCodecTypes)
    return AVCapturePhotoSettings(format: format)
  }

  func processedFormat(availableCodecs: [AVVideoCodecType]) throws -> [String: Any] {
    let codec: AVVideoCodecType
    let quality: Double
    switch self {
    case .jpeg(let value):
      codec = .jpeg
      quality = value
    case .heic(let value):
      codec = .hevc
      quality = value
    case .automatic(let value):
      codec = availableCodecs.contains(.hevc) ? .hevc : .jpeg
      quality = value
    case .dng:
      throw CaptureError.rawHasNoProcessedFormat
    }
    guard quality.isFinite, (0.0...1.0).contains(quality) else {
      throw CaptureError.invalidQuality(quality)
    }
    guard availableCodecs.contains(codec) else {
      throw CaptureError.codecUnsupported
    }
    return [
      AVVideoCodecKey: codec,
      AVVideoCompressionPropertiesKey: [AVVideoQualityKey: quality],
    ]
  }
}
