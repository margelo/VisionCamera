import Foundation

// A native callback may race an error or cancellation callback. Consume the
// continuation under the lock, then resume outside it.
final class ContinuationGuard<Value> {
  private let lock = NSLock()
  private var continuation: CheckedContinuation<Value, Error>?

  init(_ continuation: CheckedContinuation<Value, Error>) {
    self.continuation = continuation
  }

  func resume(with result: Result<Value, Error>) {
    lock.lock()
    let continuation = self.continuation
    self.continuation = nil
    lock.unlock()
    continuation?.resume(with: result)
  }
}
