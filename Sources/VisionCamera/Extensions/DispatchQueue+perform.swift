import Foundation

extension DispatchQueue {
  /// Completes infallible work, including cleanup, even when the caller's task is cancelled.
  func perform<Value>(_ operation: @escaping () -> Value) async -> Value {
    await withCheckedContinuation { continuation in
      async {
        continuation.resume(returning: operation())
      }
    }
  }

  func perform<Value>(_ operation: @escaping () throws -> Value) async throws -> Value {
    try Task.checkCancellation()
    return try await withCheckedThrowingContinuation { continuation in
      async {
        continuation.resume(with: Result(catching: operation))
      }
    }
  }
}
