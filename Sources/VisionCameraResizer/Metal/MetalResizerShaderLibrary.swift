// Copyright © 2025 Marc Rousavy @ Margelo
// Adapted from Marc Rousavy's MetalResizerShaderLibrary, created 11.03.26.

import Foundation
import Metal

enum MetalResizerShaderLibrary {
  static func createPipelineState(device: MTLDevice, options: ResizerOptions) throws -> MTLComputePipelineState {
    let bundle = try shaderBundle()
    do {
      let library = try device.makeDefaultLibrary(bundle: bundle)
      let function = try library.makeFunction(name: functionName(for: options.dataType), constantValues: constants(for: options))
      return try device.makeComputePipelineState(function: function)
    } catch {
      throw GPUResizerError.metalFailure("Failed to load or specialize VisionCameraResizer's compiled Metal shaders: \(error.localizedDescription)")
    }
  }

  private static func functionName(for dataType: ResizerDataType) -> String {
    switch dataType {
    case .uint8: return "resize_uint8"
    case .int8: return "resize_int8"
    case .float16: return "resize_float16"
    case .float32: return "resize_float32"
    }
  }

  private static func constants(for options: ResizerOptions) -> MTLFunctionConstantValues {
    let constants = MTLFunctionConstantValues()
    var channelOrder = options.channelOrder.rawValue
    var pixelLayout = options.pixelLayout.rawValue
    var channelCount: UInt32 = 3
    var scaleMode = options.scaleMode.rawValue
    constants.setConstantValue(&channelOrder, type: .uint, index: 0)
    constants.setConstantValue(&pixelLayout, type: .uint, index: 1)
    constants.setConstantValue(&channelCount, type: .uint, index: 2)
    constants.setConstantValue(&scaleMode, type: .uint, index: 3)
    return constants
  }

  private static func shaderBundle() throws -> Bundle {
    #if SWIFT_PACKAGE
      return Bundle.module
    #else
      for container in [Bundle(for: GPUResizer.self), Bundle.main] {
        if let url = container.url(forResource: "VisionCameraResizer", withExtension: "bundle"), let bundle = Bundle(url: url) {
          return bundle
        }
      }
      throw GPUResizerError.shaderBundleMissing
    #endif
  }
}
