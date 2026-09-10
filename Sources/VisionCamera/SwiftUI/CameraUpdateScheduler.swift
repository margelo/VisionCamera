// Copyright © 2026 Marc Rousavy @ Margelo

import Foundation

/// Serializes asynchronous updates, coalescing pending requests while an operation is in flight.
@MainActor
final class CameraUpdateScheduler {
  private var pending: (() async -> Void)?
  private var task: Task<Void, Never>?

  func schedule(_ operation: @escaping () async -> Void) {
    pending = operation
    guard task == nil else { return }
    task = Task { [weak self] in
      while let operation = self?.pending {
        self?.pending = nil
        await operation()
      }
      self?.task = nil
    }
  }

  func waitUntilIdle() async {
    await task?.value
  }
}
