// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation

extension TargetPhotoContainerFormat {
  func captureSettings(for output: AVCapturePhotoOutput) throws -> AVCapturePhotoSettings {
    if self == .dng {
      guard let rawFormat = output.bestRawPixelFormat else {
        throw CameraError(message: "This photo output does not support RAW capture in its current configuration.")
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
      throw CameraError(message: "RAW capture does not use a processed photo format.")
    }
    guard quality.isFinite, (0.0...1.0).contains(quality) else {
      throw CameraError(message: "Photo compression quality must be from 0.0 to 1.0.")
    }
    guard availableCodecs.contains(codec) else {
      throw CameraError(message: "Photo codec \(codec.rawValue) is not supported by this output.")
    }
    return [
      AVVideoCodecKey: codec,
      AVVideoCompressionPropertiesKey: [AVVideoQualityKey: quality],
    ]
  }
}
