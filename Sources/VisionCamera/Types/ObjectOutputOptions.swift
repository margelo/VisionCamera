// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation

/// Options for the ``ObjectOutput``.
public struct ObjectOutputOptions: Equatable, Sendable {
  /// The types of metadata objects to scan for. Session configuration throws if the connected output does not support a requested type.
  public var enabledObjectTypes: [AVMetadataObject.ObjectType]

  /// Selects the metadata object types the output should scan for.
  ///
  /// - Parameters:
  ///   - enabledObjectTypes: The types of metadata objects to scan for. Session configuration throws if the connected output does not support a requested type.
  public init(
    enabledObjectTypes: [AVMetadataObject.ObjectType]
  ) {
    self.enabledObjectTypes = enabledObjectTypes
  }
}
