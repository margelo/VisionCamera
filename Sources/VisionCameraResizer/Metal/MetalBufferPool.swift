// Copyright © 2025 Marc Rousavy @ Margelo
// Adapted from Marc Rousavy's MetalReusableBuffer, created 11.03.26.

import Foundation
import Metal

final class MetalBufferPool {
  private let device: MTLDevice
  private let options: ResizerOptions
  private let byteCount: Int
  private let capacity: Int
  // Acquisition runs on the resizer's serial owner queue. A result can be released on another queue.
  // This lock protects only the free-list and allocation count, never GPU execution or caller code.
  private let lock = NSLock()
  private var available: [MTLBuffer] = []
  private var allocationCount = 0

  init(device: MTLDevice, options: ResizerOptions, capacity: Int) throws {
    let byteCount = try options.validatedByteCount()
    guard byteCount <= device.maxBufferLength else { throw GPUResizerError.allocationFailed(byteCount: byteCount) }
    self.device = device
    self.options = options
    self.byteCount = byteCount
    self.capacity = capacity
  }

  func acquire() throws -> GPUResizeResult {
    let buffer: MTLBuffer
    lock.lock()
    if let reusable = available.popLast() {
      lock.unlock()
      buffer = reusable
    } else {
      guard allocationCount < capacity else {
        lock.unlock()
        throw GPUResizerError.outputCapacityExceeded
      }
      allocationCount += 1
      lock.unlock()
      guard let allocated = device.makeBuffer(length: byteCount, options: .storageModeShared) else {
        lock.lock()
        allocationCount -= 1
        lock.unlock()
        throw GPUResizerError.allocationFailed(byteCount: byteCount)
      }
      allocated.label = "VisionCameraResizer.Output"
      buffer = allocated
    }
    return GPUResizeResult(options: options, buffer: buffer) { [self] in
      lock.lock()
      available.append(buffer)
      lock.unlock()
    }
  }
}
