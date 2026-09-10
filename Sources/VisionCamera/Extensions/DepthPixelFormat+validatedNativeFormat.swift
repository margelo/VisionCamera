// Copyright © 2025 Marc Rousavy @ Margelo

import CoreVideo

extension DepthPixelFormat {
  func validatedNativeFormat(availableDepthDataTypes: [OSType]) throws -> OSType {
    let nativeFormat = try toCVPixelFormatType()
    guard availableDepthDataTypes.contains(nativeFormat) else {
      throw CameraError(message: "The Depth frame cannot convert to Core Video pixel format \(nativeFormat).")
    }
    return nativeFormat
  }
}
