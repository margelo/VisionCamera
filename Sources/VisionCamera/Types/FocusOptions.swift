// Copyright © 2025 Marc Rousavy @ Margelo

/// Options for a focus metering operation via
/// ``CameraController/focus(at:options:)``
public struct FocusOptions: Equatable, Sendable {
  /// The responsiveness of the metering operation.
  /// See ``FocusResponsiveness``
  /// Defaults to ``FocusResponsiveness/snappy``.
  public var responsiveness: FocusResponsiveness
  /// The adaptiveness to changes in the scene.
  /// See ``SceneAdaptiveness``
  /// Defaults to ``SceneAdaptiveness/continuous``.
  public var adaptiveness: SceneAdaptiveness
  /// The metering modes to run this focus operation on.
  ///
  /// By default, all ``MeteringMode``s that are supported
  /// on the device will be enabled - so ideally 3A.
  ///
  /// When passing a custom value, you are responsible for ensuring
  /// that the given modes are compatible - e.g. when passing `[.af]`
  /// you must ensure that the ``CameraDevice`` supports focus
  /// metering - see ``CameraDevice/supportsFocusMetering``.
  ///
  /// See ``MeteringMode``
  /// When `nil`, all metering modes supported by the device are enabled.
  public var modes: [MeteringMode]?
  /// Controls whether focus automatically returns to continuous focus after it has settled.
  ///
  /// Use ``FocusReset/after(_:)`` to specify a delay in seconds, or ``FocusReset/never`` to keep the
  /// metering configuration until focus is reset manually or another metering operation starts.
  ///
  /// The default delay is five seconds.
  public var reset: FocusReset

  /// Creates the metering options for a focus operation.
  ///
  /// - Parameters:
  ///   - responsiveness: The responsiveness of the metering operation. See ``FocusResponsiveness`` Defaults to ``FocusResponsiveness/snappy``.
  ///   - adaptiveness: The adaptiveness to changes in the scene. See ``SceneAdaptiveness`` Defaults to ``SceneAdaptiveness/continuous``.
  ///   - modes: The metering modes to run this focus operation on.
  ///   - reset: Controls whether focus automatically returns to continuous focus after it has settled.
  public init(
    responsiveness: FocusResponsiveness = .snappy,
    adaptiveness: SceneAdaptiveness = .continuous,
    modes: [MeteringMode]? = nil,
    reset: FocusReset = .after(5)
  ) {
    self.responsiveness = responsiveness
    self.adaptiveness = adaptiveness
    self.modes = modes
    self.reset = reset
  }
}
