// Copyright © 2025 Marc Rousavy @ Margelo

import Metal

/// An owned, completed output tensor that retains one buffer from its resizer's bounded pool.
///
/// ARC releases the pool slot when this result is deallocated. Other resize calls cannot overwrite a retained result.
/// The result remains valid after its source Frame or resizer is released. Retain the result until all reads finish,
/// including any commands you submit to Metal. Accessors do not copy the output.
public final class GPUResizeResult {
  /// The output width in pixels.
  public var width: Int { options.width }
  /// The output height in pixels.
  public var height: Int { options.height }
  /// The output tensor's channel ordering.
  public var channelOrder: ResizerChannelOrder { options.channelOrder }
  /// The output tensor's scalar encoding.
  public var dataType: ResizerDataType { options.dataType }
  /// The output tensor's channel arrangement.
  public var pixelLayout: ResizerPixelLayout { options.pixelLayout }
  /// The exact tightly packed byte count, equal to width times height times three channels times the scalar size.
  public var byteCount: Int { buffer.length }
  private let options: ResizerOptions
  private let buffer: MTLBuffer
  private let release: () -> Void

  init(options: ResizerOptions, buffer: MTLBuffer, release: @escaping () -> Void) {
    self.options = options
    self.buffer = buffer
    self.release = release
  }

  deinit {
    release()
  }

  /// Provides read-only CPU access to the completed shared buffer without a copy.
  ///
  /// The pointer is valid only within `body` and must not escape. Return `Data(bytes)` to make an independent copy.
  /// The result remains retained for the entire closure, including when the closure throws.
  public func withUnsafeBytes<Result>(_ body: (UnsafeRawBufferPointer) throws -> Result) rethrows -> Result {
    return try withExtendedLifetime(self) {
      try body(UnsafeRawBufferPointer(start: buffer.contents(), count: buffer.length))
    }
  }

  /// Provides the shared Metal buffer for encoding reads without copying its bytes.
  ///
  /// Treat this buffer as read-only. Retaining the native `MTLBuffer` alone does not retain the pool lease.
  /// For asynchronous GPU commands, capture this result in a completion handler so its lease remains alive until those commands finish.
  /// The result stays retained during `body`, but the closure's return does not wait for commands that your code submits.
  public func withMetalBuffer<Result>(_ body: (MTLBuffer) throws -> Result) rethrows -> Result {
    return try withExtendedLifetime(self) { try body(buffer) }
  }
}
