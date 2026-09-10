// Copyright © 2025 Marc Rousavy @ Margelo

import Foundation

/// A configuration, input, resource, or execution failure in the GPU resizer.
public enum GPUResizerError: Error, LocalizedError, Equatable {
  /// The dimensions are nonpositive or exceed the kernel's 32-bit channel index range.
  case invalidDimensions
  /// The maximum number of outstanding results is nonpositive.
  case invalidCapacity
  /// No Metal device is available.
  case metalUnavailable
  /// The requested shared GPU buffer could not be allocated.
  case allocationFailed(byteCount: Int)
  /// All result buffers are retained. Release a result before processing another frame.
  case outputCapacityExceeded
  /// The input is not full-range, 8-bit, bi-planar NV12.
  case unsupportedPixelFormat(UInt32)
  /// A Core Video texture operation failed with the supplied status.
  case textureCreationFailed(plane: Int, status: Int32)
  /// The installed shader resource bundle is missing.
  case shaderBundleMissing
  /// Metal pipeline creation or execution failed with the supplied description.
  case metalFailure(String)

  /// A readable description of the failure.
  public var errorDescription: String? {
    switch self {
    case .invalidDimensions: return "Output dimensions must be positive and fit the 32-bit channel index range."
    case .invalidCapacity: return "maximumOutstandingResults must be positive."
    case .metalUnavailable: return "No Metal device is available."
    case .allocationFailed(let byteCount): return "Failed to allocate a \(byteCount)-byte Metal output buffer."
    case .outputCapacityExceeded: return "All GPU resize results are still retained. Release a result before resizing another frame."
    case .unsupportedPixelFormat(let format): return "Unsupported input pixel format \(format). Use full-range 8-bit bi-planar NV12."
    case .textureCreationFailed(let plane, let status): return "Failed to create Metal texture for plane \(plane), Core Video status \(status)."
    case .shaderBundleMissing: return "VisionCameraResizer.bundle is missing. Reinstall the package resources and rebuild."
    case .metalFailure(let message): return message
    }
  }
}
