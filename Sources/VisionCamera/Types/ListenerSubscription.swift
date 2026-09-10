// Copyright © 2025 Marc Rousavy @ Margelo

/// Represents a subscription to any kind of
/// listener.
///
/// You can remove the subscription by calling
/// ``ListenerSubscription/remove``.
public struct ListenerSubscription {
  /// Removes the listener subscription.
  ///
  /// Call this when the owner no longer needs to receive events, such as when a Camera screen disappears.
  public var remove: () -> Void

  /// Creates a subscription with the operation that removes its listener.
  ///
  /// - Parameters:
  ///   - remove: Removes the listener subscription.
  public init(
    remove: @escaping () -> Void
  ) {
    self.remove = remove
  }
}
