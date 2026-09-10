import AVFoundation
import Foundation

extension AVCaptureDevice {
  // The device lock protects scheduling the native operation, not its completion.
  func withLock(
    _ queue: DispatchQueue,
    _ operation:
      @escaping (
        _ resolve: @escaping () -> Void,
        _ reject: @escaping (Error) -> Void
      ) throws -> Void
  ) async throws {
    try Task.checkCancellation()
    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
      let completion = ContinuationGuard(continuation)
      queue.async(
        execute: DispatchWorkItem {
          do {
            try self.lockForConfiguration()
            defer { self.unlockForConfiguration() }
            try operation(
              { completion.resume(with: .success(())) },
              { completion.resume(with: .failure($0)) }
            )
          } catch {
            completion.resume(with: .failure(error))
          }
        })
    }
  }

  func withLock(
    _ queue: DispatchQueue,
    _ operation: @escaping (_ completion: @escaping () -> Void) throws -> Void
  ) async throws {
    try await withLock(queue) { resolve, _ in try operation(resolve) }
  }

  func withLock(_ queue: DispatchQueue, _ operation: @escaping () throws -> Void) async throws {
    try await queue.perform {
      try self.lockForConfiguration()
      defer { self.unlockForConfiguration() }
      try operation()
    }
  }
}
