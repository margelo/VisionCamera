// Copyright © 2025 Marc Rousavy @ Margelo

import CoreGraphics

/// Configuration options for a ``DepthOutput``.
///
/// See ``DepthOutput``
public struct DepthOutputOptions: Equatable, Sendable {
  /// Enables or disables depth data filtering to
  /// smoothen out uneven spots in the depth map.
  ///
  /// Defaults to `true`.
  public var isFilteringEnabled: Bool
  /// The target Depth Resolution to use.
  ///
  /// To include this output's ``DepthOutputOptions/targetResolution`` in
  /// ``CameraSession`` format negotiation, add a ``Constraint/resolution(_:)``
  /// for this output. The session will negotiate it with constraints (such
  /// as HDR, FPS, etc) in a ``CameraSessionConfig`` to
  /// finalize the Resolution used for the Output.
  /// Append resolution biases after explicit constraints when they should have lower priority.
  /// This is therefore merely a resolution _target_, and may
  /// not be exactly met.
  ///
  /// If the given ``DepthOutputOptions/targetResolution`` cannot be met
  /// exactly, its aspect ratio (computed by
  /// `CGSize.width` / `CGSize.height`) will
  /// be prioritized over pixel count.
  ///
  /// Defaults to 480 by 854 pixels.
  public var targetResolution: CGSize
  /// Enable (or disable) physical buffer rotation.
  ///
  /// - When ``DepthOutputOptions/rotatesBuffers`` is set to `true`, and
  /// the ``DepthOutput``'s ``DepthOutput/outputOrientation``
  /// is set to any value different than the Camera sensor's native orientation, the Camera pipeline
  /// will physically rotate the buffers to apply the orientation.
  /// The resulting ``Depth``'s ``Depth/orientation``
  /// will then always be ``CameraOrientation/up``, meaning it no longer needs to be rotated by the consumer.
  /// - When ``DepthOutputOptions/rotatesBuffers`` is set to `false`, the Camera
  /// pipeline will not physically rotate buffers, but instead only provide the ``Depth``'s
  /// orientation relative to the ``DepthOutput``'s target
  /// ``DepthOutput/outputOrientation``
  /// as metadata (see ``Depth/orientation``), meaning the consumers have to
  /// handle orientation themselves - e.g. by reading pixels in a different order, or
  /// applying orientation in a GPU rendering pass, depending on the use-case.
  ///
  /// Setting ``DepthOutputOptions/rotatesBuffers`` to `true` introduces
  /// processing overhead.
  /// Defaults to false.
  public var rotatesBuffers: Bool
  /// Whether to drop new depth frames when they arrive while the
  /// frame callback is still executing.
  ///
  /// - If set to `true`, the ``DepthOutput`` will
  /// automatically drop any depth frames that arrive while your frame callback is still executing to avoid
  /// exhausting resources,
  /// at the risk of losing information since depth frames may be dropped.
  /// - If set to `false`, the ``DepthOutput`` will
  /// queue up any depth frames that arrive while your frame callback
  /// is still executing and immediately call it once it is free
  /// again, at the risk of exhausting resources and growing RAM.
  ///
  /// Defaults to true.
  public var discardsLateFrames: Bool
  /// Allow this output to start later in the capture pipeline startup process.
  ///
  /// Enabling this lets the camera prioritize outputs needed for preview first,
  /// then start the ``DepthOutput`` shortly afterwards.
  ///
  /// This can improve startup behavior when preview responsiveness is more
  /// important than receiving frames immediately.
  ///
  /// Defaults to `true`.
  ///
  /// This option is applied on iOS 26 and later when the output supports deferred start.
  public var allowsDeferredStart: Bool

  /// Creates depth-output options, with filtering enabled by default.
  ///
  /// - Parameters:
  ///   - isFilteringEnabled: Enables or disables depth data filtering to smoothen out uneven spots in the depth map.
  ///   - targetResolution: The target Depth Resolution to use.
  ///   - rotatesBuffers: Enable (or disable) physical buffer rotation.
  ///   - discardsLateFrames: Whether to drop new depth frames when they arrive while the frame callback is still executing.
  ///   - allowsDeferredStart: Allow this output to start later in the capture pipeline startup process.
  public init(
    isFilteringEnabled: Bool = true,
    targetResolution: CGSize = CGSize(width: 480, height: 854),
    rotatesBuffers: Bool = false,
    discardsLateFrames: Bool = true,
    allowsDeferredStart: Bool = true
  ) {
    self.isFilteringEnabled = isFilteringEnabled
    self.targetResolution = targetResolution
    self.rotatesBuffers = rotatesBuffers
    self.discardsLateFrames = discardsLateFrames
    self.allowsDeferredStart = allowsDeferredStart
  }
}
