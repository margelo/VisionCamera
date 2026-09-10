// Copyright © 2025 Marc Rousavy @ Margelo

import CoreVideo

extension TargetVideoPixelFormat {
  func videoSettings(availablePixelFormats: [OSType]) throws -> [String: Any] {
    switch self {
    case .native:
      return [:]
    case .pixelFormat(let pixelFormat):
      guard availablePixelFormats.contains(pixelFormat.rawValue) else {
        throw ConfigurationError.pixelFormatUnavailable
      }
      return [kCVPixelBufferPixelFormatTypeKey as String: pixelFormat.rawValue]
    }
  }
}
