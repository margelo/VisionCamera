// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation
import Foundation
import simd

extension CMSampleBuffer {
  var cameraIntrinsicMatrix: simd_float3x3? {
    guard CMSampleBufferIsValid(self),
      let attachment = attachments[.cameraIntrinsicMatrix],
      let data = attachment.value as? Data,
      data.count >= MemoryLayout<simd_float3x3>.size
    else { return nil }
    return data.withUnsafeBytes { $0.loadUnaligned(as: simd_float3x3.self) }
  }
}
