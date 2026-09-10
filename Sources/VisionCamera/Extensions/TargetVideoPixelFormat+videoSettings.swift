// Copyright © 2025 Marc Rousavy @ Margelo

import CoreVideo

extension TargetVideoPixelFormat {
  func videoSettings(availablePixelFormats: [OSType]) throws -> [String: Any] {
    switch self {
    case .native:
      return [:]
    case .pixelFormat(let pixelFormat):
      guard availablePixelFormats.contains(pixelFormat.rawValue) else {
        throw CameraError(message: "The connected FrameOutput does not support Core Video pixel format \(pixelFormat.rawValue).")
      }
      return [kCVPixelBufferPixelFormatTypeKey as String: pixelFormat.rawValue]
    }
  }
}
