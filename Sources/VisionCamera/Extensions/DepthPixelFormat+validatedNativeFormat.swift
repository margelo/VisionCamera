// Copyright © 2025 Marc Rousavy @ Margelo

import CoreVideo

extension DepthPixelFormat {
  func validatedNativeFormat(availableDepthDataTypes: [OSType]) throws -> OSType {
    let nativeFormat = try cvPixelFormat
    guard availableDepthDataTypes.contains(nativeFormat) else {
      throw MediaError.unsupportedDepthPixelFormat(self)
    }
    return nativeFormat
  }
}
