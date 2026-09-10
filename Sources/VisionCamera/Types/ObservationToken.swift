// Copyright © 2025 Marc Rousavy @ Margelo

import Foundation

/// Keeps an observation active until it is cancelled or released.
///
/// Retain this token for as long as you need events. Call ``cancel()`` to stop observing early.
/// An event already being delivered may finish after cancellation.
public final class ObservationToken {
  // Cancellation may race with another caller or the owner's teardown. Protect only the
  // cancellation closure; the observed object still owns its listener queue.
  private let lock = NSLock()
  private var cancellation: (() -> Void)?

  /// Creates a token that performs the supplied cleanup exactly once.
  /// - Parameter cancellation: Removes the observation on its owning queue.
  public init(_ cancellation: @escaping () -> Void) {
    self.cancellation = cancellation
  }

  /// Cancels this observation. Calling this more than once has no effect.
  public func cancel() {
    lock.lock()
    let cancellation = self.cancellation
    self.cancellation = nil
    lock.unlock()
    cancellation?()
  }

  deinit { cancel() }
}
