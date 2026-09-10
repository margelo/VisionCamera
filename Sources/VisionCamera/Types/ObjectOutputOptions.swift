// Copyright © 2025 Marc Rousavy @ Margelo

/// Options for the ``CameraObjectOutput``.
public struct ObjectOutputOptions: Equatable, Sendable {
  /// The types of metadata objects to scan for. Only types supported by the connected output are enabled.
  public var enabledObjectTypes: [ScannedObjectType]

  /// Selects the metadata object types the output should scan for.
  ///
  /// - Parameters:
  ///   - enabledObjectTypes: The types of metadata objects to scan for. Only types supported by the connected output are enabled.
  public init(
    enabledObjectTypes: [ScannedObjectType]
  ) {
    self.enabledObjectTypes = enabledObjectTypes
  }
}
