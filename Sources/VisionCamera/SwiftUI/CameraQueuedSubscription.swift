// Copyright © 2026 Marc Rousavy @ Margelo

import Foundation

/// Keeps registration and removal on the queue that owns a subscription's native side effects.
final class CameraQueuedSubscription {
  private let queue: DispatchQueue
  private var subscription: ListenerSubscription?

  init(queue: DispatchQueue, subscribe: @escaping () -> ListenerSubscription) {
    self.queue = queue
    queue.async(execute: DispatchWorkItem { self.subscription = subscribe() })
  }

  func remove() {
    queue.async(
      execute: DispatchWorkItem {
        self.subscription?.remove()
        self.subscription = nil
      })
  }
}
