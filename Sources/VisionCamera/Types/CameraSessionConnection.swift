// Copyright © 2025 Marc Rousavy @ Margelo

/// Specifies a single Camera input stream connection
/// streaming into zero or more outputs.
public struct CameraSessionConnection {
  /// The input device of this ``CameraSessionConnection``.
  /// This ``CameraDevice`` will stream into all given ``CameraSessionConnection/outputs``.
  ///
  /// Pass ``CameraDeviceOrPosition/position(_:)`` to automatically select the default ``CameraDevice`` at
  /// the given position.
  public var input: CameraDeviceOrPosition
  /// All output configurations that the given ``CameraSessionConnection/input``
  /// device will stream into.
  public var outputs: [CameraOutputConfiguration]
  /// Constraints specifically for this connection.
  ///
  /// Earlier constraints have higher priority. Append output resolution-bias constraints after explicit
  /// constraints when resolution should have lower priority.
  public var constraints: [Constraint]
  /// Sets the initial ``CameraController/zoom``
  /// value for the ``CameraController``.
  ///
  /// This value can later be adjusted
  /// via ``CameraController/setZoom(_:)``.
  public var initialZoom: Double?
  /// Sets the initial ``CameraController/exposureBias``
  /// value for the ``CameraController``.
  ///
  /// This value can later be adjusted
  /// via ``CameraController/setExposureBias(_:)``.
  public var initialExposureBias: Double?
  /// A callback that will be called after the given ``CameraSessionConnection/constraints`` have
  /// been fully resolved, and a valid ``CameraSessionConfig`` has been
  /// constructed.
  ///
  /// This is equivalent to calling
  /// ``VisionCamera/resolve(_:for:outputs:requiresMultiCam:)``
  /// with the ``CameraSessionConnection/input``, ``CameraSessionConnection/outputs`` and
  /// ``CameraSessionConnection/constraints`` listed here.
  ///
  /// The given `config` can be used to provide visual feedback in
  /// Camera apps where buttons have to be greyed out when they are not supported,
  /// e.g. when passing a HDR ``Constraint`` but the session didn't end up
  /// selecting a ``CameraSessionConfig/selectedVideoDynamicRange``.
  ///
  /// The callback runs on the session's serial configuration queue.
  public var onSessionConfigSelected: ((_ config: CameraSessionConfig) -> Void)?

  /// Describes an input, its outputs, and the constraints used to negotiate their capture configuration.
  ///
  /// - Parameters:
  ///   - input: The input device of this ``CameraSessionConnection``. This ``CameraDevice`` will stream into all given ``CameraSessionConnection/outputs``.
  ///   - outputs: All output configurations that the given ``CameraSessionConnection/input`` device will stream into.
  ///   - constraints: Constraints specifically for this connection.
  ///   - initialZoom: Sets the initial ``CameraController/zoom`` value for the ``CameraController``.
  ///   - initialExposureBias: Sets the initial ``CameraController/exposureBias`` value for the ``CameraController``.
  ///   - onSessionConfigSelected: A callback that will be called after the given ``CameraSessionConnection/constraints`` have been fully resolved, and a valid ``CameraSessionConfig`` has been constructed.
  public init(
    input: CameraDeviceOrPosition,
    outputs: [CameraOutputConfiguration],
    constraints: [Constraint] = [],
    initialZoom: Double? = nil,
    initialExposureBias: Double? = nil,
    onSessionConfigSelected: ((_ config: CameraSessionConfig) -> Void)? = nil
  ) {
    self.input = input
    self.outputs = outputs
    self.constraints = constraints
    self.initialZoom = initialZoom
    self.initialExposureBias = initialExposureBias
    self.onSessionConfigSelected = onSessionConfigSelected
  }
}
