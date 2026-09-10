// Copyright © 2025 Marc Rousavy @ Margelo
// Adapted from Marc Rousavy's implementation, created 11.03.26.

import CoreVideo
import Metal

struct MetalPlaneTexture {
  // Core Video requires retaining this wrapper until GPU work completes, not only its MTLTexture.
  let cvTexture: CVMetalTexture
  let texture: MTLTexture

  init(pixelBuffer: CVPixelBuffer, cache: CVMetalTextureCache, format: MTLPixelFormat, plane: Int) throws {
    var cvTexture: CVMetalTexture?
    let status = CVMetalTextureCacheCreateTextureFromImage(
      kCFAllocatorDefault, cache, pixelBuffer, nil, format,
      CVPixelBufferGetWidthOfPlane(pixelBuffer, plane), CVPixelBufferGetHeightOfPlane(pixelBuffer, plane),
      plane, &cvTexture)
    guard status == kCVReturnSuccess, let cvTexture, let texture = CVMetalTextureGetTexture(cvTexture) else {
      throw GPUResizerError.textureCreationFailed(plane: plane, status: status)
    }
    self.cvTexture = cvTexture
    self.texture = texture
  }
}
