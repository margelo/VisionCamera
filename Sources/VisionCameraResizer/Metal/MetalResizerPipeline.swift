// Copyright © 2025 Marc Rousavy @ Margelo
// Adapted from Marc Rousavy's MetalResizerPipeline, created 11.03.26.

import CoreVideo
import Metal

final class MetalResizerPipeline {
  private let options: ResizerOptions
  private let commandQueue: MTLCommandQueue
  private let textureCache: CVMetalTextureCache
  private let pipelineState: MTLComputePipelineState
  private let threadsPerThreadgroup: MTLSize
  private let outputPool: MetalBufferPool

  init(options: ResizerOptions, capacity: Int) throws {
    guard let device = MTLCreateSystemDefaultDevice() else { throw GPUResizerError.metalUnavailable }
    guard let commandQueue = device.makeCommandQueue() else {
      throw GPUResizerError.metalFailure("Failed to create the Metal command queue.")
    }
    let pipelineState = try MetalResizerShaderLibrary.createPipelineState(device: device, options: options)
    let groupWidth = min(pipelineState.threadExecutionWidth, 16)
    let groupHeight = max(1, min(16, pipelineState.maxTotalThreadsPerThreadgroup / max(groupWidth, 1)))
    var textureCache: CVMetalTextureCache?
    let status = CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &textureCache)
    guard status == kCVReturnSuccess, let textureCache else {
      throw GPUResizerError.metalFailure("Failed to create the Core Video Metal texture cache, status \(status).")
    }
    self.options = options
    self.commandQueue = commandQueue
    self.textureCache = textureCache
    self.pipelineState = pipelineState
    self.threadsPerThreadgroup = MTLSize(width: groupWidth, height: groupHeight, depth: 1)
    self.outputPool = try MetalBufferPool(device: device, options: options, capacity: capacity)
  }

  deinit {
    CVMetalTextureCacheFlush(textureCache, 0)
  }

  func run(pixelBuffer: CVPixelBuffer, rotationDegrees: Int32, isMirrored: Bool) throws -> GPUResizeResult {
    let result = try outputPool.acquire()
    let yPlane = try MetalPlaneTexture(pixelBuffer: pixelBuffer, cache: textureCache, format: .r8Unorm, plane: 0)
    let uvPlane = try MetalPlaneTexture(pixelBuffer: pixelBuffer, cache: textureCache, format: .rg8Unorm, plane: 1)
    try withExtendedLifetime((pixelBuffer, yPlane, uvPlane)) {
      try result.withMetalBuffer { buffer in
        try encodeAndRun(yPlane: yPlane, uvPlane: uvPlane, buffer: buffer, rotationDegrees: rotationDegrees, isMirrored: isMirrored)
      }
    }
    return result
  }

  private func encodeAndRun(yPlane: MetalPlaneTexture, uvPlane: MetalPlaneTexture, buffer: MTLBuffer, rotationDegrees: Int32, isMirrored: Bool) throws {
    guard let commandBuffer = commandQueue.makeCommandBuffer(), let encoder = commandBuffer.makeComputeCommandEncoder() else {
      throw GPUResizerError.metalFailure("Failed to create the Metal command buffer or compute encoder.")
    }
    var uniforms = MetalResizerUniforms(
      outputWidth: UInt32(options.width), outputHeight: UInt32(options.height),
      rotationDegrees: rotationDegrees, isMirrored: isMirrored ? 1 : 0)
    let grid = MTLSize(
      width: (options.width + threadsPerThreadgroup.width - 1) / threadsPerThreadgroup.width,
      height: (options.height + threadsPerThreadgroup.height - 1) / threadsPerThreadgroup.height,
      depth: 1)
    encoder.setComputePipelineState(pipelineState)
    encoder.setTexture(yPlane.texture, index: 0)
    encoder.setTexture(uvPlane.texture, index: 1)
    encoder.setBuffer(buffer, offset: 0, index: 0)
    encoder.setBytes(&uniforms, length: MemoryLayout<MetalResizerUniforms>.stride, index: 1)
    encoder.dispatchThreadgroups(grid, threadsPerThreadgroup: threadsPerThreadgroup)
    encoder.endEncoding()
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()
    guard commandBuffer.status == .completed else {
      throw GPUResizerError.metalFailure(commandBuffer.error?.localizedDescription ?? "The Metal resize command did not complete.")
    }
  }
}
