// Copyright © 2025 Marc Rousavy @ Margelo

/// Configuration options for a ``CameraDepthFrameOutput``.
///
/// See ``CameraDepthFrameOutput``
public struct DepthFrameOutputOptions: Equatable, Sendable {
  /// Enables or disables depth data filtering to
  /// smoothen out uneven spots in the depth map.
  ///
  /// Defaults to `true`.
  public var enableFiltering: Bool
  /// The target Depth Resolution to use.
  ///
  /// To include this output's ``DepthFrameOutputOptions/targetResolution`` in
  /// ``CameraSession`` format negotiation, add a ``ResolutionBiasConstraint``
  /// for this output. The session will negotiate it with constraints (such
  /// as HDR, FPS, etc) in a ``CameraSessionConfig`` to
  /// finalize the Resolution used for the Output.
  /// Append resolution biases after explicit constraints when they should have lower priority.
  /// This is therefore merely a resolution _target_, and may
  /// not be exactly met.
  ///
  /// If the given ``DepthFrameOutputOptions/targetResolution`` cannot be met
  /// exactly, its aspect ratio (computed by
  /// ``Size/width`` / ``Size/height``) will
  /// be prioritized over pixel count.
  ///
  /// Defaults to 480 by 854 pixels.
  public var targetResolution: Size
  /// Enable (or disable) physical buffer rotation.
  ///
  /// - When ``DepthFrameOutputOptions/enablePhysicalBufferRotation`` is set to `true`, and
  /// the ``CameraDepthFrameOutput``'s ``CameraDepthFrameOutput/outputOrientation``
  /// is set to any value different than the Camera sensor's native orientation, the Camera pipeline
  /// will physically rotate the buffers to apply the orientation.
  /// The resulting ``Depth``'s ``Depth/orientation``
  /// will then always be ``CameraOrientation/up``, meaning it no longer needs to be rotated by the consumer.
  /// - When ``DepthFrameOutputOptions/enablePhysicalBufferRotation`` is set to `false`, the Camera
  /// pipeline will not physically rotate buffers, but instead only provide the ``Depth``'s
  /// orientation relative to the ``CameraDepthFrameOutput``'s target
  /// ``CameraDepthFrameOutput/outputOrientation``
  /// as metadata (see ``Depth/orientation``), meaning the consumers have to
  /// handle orientation themselves - e.g. by reading pixels in a different order, or
  /// applying orientation in a GPU rendering pass, depending on the use-case.
  ///
  /// Setting ``DepthFrameOutputOptions/enablePhysicalBufferRotation`` to `true` introduces
  /// processing overhead.
  /// Defaults to false.
  public var enablePhysicalBufferRotation: Bool
  /// Whether to drop new depth frames when they arrive while the
  /// frame callback is still executing.
  ///
  /// - If set to `true`, the ``CameraDepthFrameOutput`` will
  /// automatically drop any depth frames that arrive while your frame callback is still executing to avoid
  /// exhausting resources,
  /// at the risk of losing information since depth frames may be dropped.
  /// - If set to `false`, the ``CameraDepthFrameOutput`` will
  /// queue up any depth frames that arrive while your frame callback
  /// is still executing and immediately call it once it is free
  /// again, at the risk of exhausting resources and growing RAM.
  ///
  /// Defaults to true.
  public var dropFramesWhileBusy: Bool
  /// Allow this output to start later in the capture pipeline startup process.
  ///
  /// Enabling this lets the camera prioritize outputs needed for preview first,
  /// then start the ``CameraDepthFrameOutput`` shortly afterwards.
  ///
  /// This can improve startup behavior when preview responsiveness is more
  /// important than receiving frames immediately.
  ///
  /// Defaults to `true`.
  ///
  /// This option is applied on iOS 26 and later when the output supports deferred start.
  public var allowDeferredStart: Bool

  /// Creates depth-output options, with filtering enabled by default.
  ///
  /// - Parameters:
  ///   - enableFiltering: Enables or disables depth data filtering to smoothen out uneven spots in the depth map.
  ///   - targetResolution: The target Depth Resolution to use.
  ///   - enablePhysicalBufferRotation: Enable (or disable) physical buffer rotation.
  ///   - dropFramesWhileBusy: Whether to drop new depth frames when they arrive while the frame callback is still executing.
  ///   - allowDeferredStart: Allow this output to start later in the capture pipeline startup process.
  public init(
    enableFiltering: Bool = true,
    targetResolution: Size = Size(width: 480, height: 854),
    enablePhysicalBufferRotation: Bool = false,
    dropFramesWhileBusy: Bool = true,
    allowDeferredStart: Bool = true
  ) {
    self.enableFiltering = enableFiltering
    self.targetResolution = targetResolution
    self.enablePhysicalBufferRotation = enablePhysicalBufferRotation
    self.dropFramesWhileBusy = dropFramesWhileBusy
    self.allowDeferredStart = allowDeferredStart
  }
}
