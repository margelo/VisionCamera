// Copyright © 2025 Marc Rousavy @ Margelo

public struct ListenerSubscription {
  public var remove: () -> Void

  public init(
    remove: @escaping () -> Void
  ) {
    self.remove = remove
  }
}
