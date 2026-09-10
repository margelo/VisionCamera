import Foundation

extension DispatchQueue {
  func perform<Value>(_ operation: @escaping () throws -> Value) async throws -> Value {
    try Task.checkCancellation()
    return try await withCheckedThrowingContinuation { continuation in
      async {
        continuation.resume(with: Result(catching: operation))
      }
    }
  }
}
