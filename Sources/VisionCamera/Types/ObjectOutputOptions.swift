// Copyright © 2025 Marc Rousavy @ Margelo

public struct ObjectOutputOptions: Equatable, Sendable {
  public var enabledObjectTypes: [ScannedObjectType]

  public init(
    enabledObjectTypes: [ScannedObjectType]
  ) {
    self.enabledObjectTypes = enabledObjectTypes
  }
}
