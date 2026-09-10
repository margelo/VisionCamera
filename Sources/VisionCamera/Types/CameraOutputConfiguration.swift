// Copyright © 2025 Marc Rousavy @ Margelo

/// Specifies options for an output in a ``CameraSessionConnection``
/// used in ``CameraSession/configure(connections:config:)``.
public struct CameraOutputConfiguration {
  /// Sets whether the ``CameraOutput``
  /// is mirrored alongside the vertical axis, or not.
  ///
  /// By default, ``CameraOutputConfiguration/mirrorMode`` is set to
  /// `auto`, which automatically
  /// enables video mirroring if the device suggests it -
  /// for example on selfie cameras.
  /// Defaults to `auto`.
  public var mirrorMode: MirrorMode
  /// The ``CameraOutput``.
  public var output: any CameraOutput

  /// Connects an output with the chosen mirroring behavior.
  ///
  /// - Parameters:
  ///   - mirrorMode: Sets whether the ``CameraOutput`` is mirrored alongside the vertical axis, or not.
  ///   - output: The ``CameraOutput``.
  public init(
    mirrorMode: MirrorMode = .auto,
    output: any CameraOutput
  ) {
    self.mirrorMode = mirrorMode
    self.output = output
  }
}
