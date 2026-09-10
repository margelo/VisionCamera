// Copyright © 2025 Marc Rousavy @ Margelo

/// Configuration options for a ``CameraFrameOutput``.
///
/// See ``CameraFrameOutput``
public struct FrameOutputOptions: Equatable, Sendable {
  /// The target Frame Resolution to use.
  ///
  /// To include this output's ``FrameOutputOptions/targetResolution`` in
  /// ``CameraSession`` format negotiation, add a ``ResolutionBiasConstraint``
  /// for this output. The session will negotiate it with constraints (such
  /// as HDR, FPS, etc) in a ``CameraSessionConfig`` to
  /// finalize the Resolution used for the Output.
  /// Append resolution biases after explicit constraints when they should have lower priority.
  /// This is therefore merely a resolution _target_, and may
  /// not be exactly met.
  ///
  /// If the given ``FrameOutputOptions/targetResolution`` cannot be met
  /// exactly, its aspect ratio (computed by
  /// ``Size/width`` / ``Size/height``) will
  /// be prioritized over pixel count.
  ///
  /// Defaults to 720 by 1280 pixels.
  public var targetResolution: Size
  /// Deliver smaller, preview-sized output buffers for frame processing.
  ///
  /// This is useful for ML and computer vision workloads where full-resolution
  /// buffers are unnecessary and would only increase memory bandwidth and
  /// processing costs.
  ///
  /// Other camera outputs (for example ``CameraVideoOutput``) keep using
  /// the full-resolution output negotiated by the ``CameraSession``.
  ///
  /// Defaults to false.
  ///
  /// This option is applied on iOS 17 and later.
  public var enablePreviewSizedOutputBuffers: Bool
  /// Allow this output to start later in the capture pipeline startup process.
  ///
  /// Enabling this lets the camera prioritize outputs needed for preview first,
  /// then start the ``CameraFrameOutput`` shortly afterwards.
  ///
  /// This can improve startup behavior when preview responsiveness is more
  /// important than receiving frames immediately.
  ///
  /// Defaults to `true`.
  ///
  /// This option is applied on iOS 26 and later when the output supports deferred start.
  public var allowDeferredStart: Bool
  /// Sets the pixel format of the ``CameraFrameOutput``.
  ///
  /// The most efficient format is ``TargetVideoPixelFormat/native``, which uses the selected Camera format
  /// without requesting conversion. Use ``TargetVideoPixelFormat/yuv`` for CPU access to YUV samples, or
  /// ``TargetVideoPixelFormat/rgb`` when your processing requires BGRA.
  ///
  /// RGB uses about 2.6 times more bandwidth than 8-bit YUV 4:2:0 and may require additional conversion.
  /// Prefer the native format when your processing can use it.
  ///
  /// Defaults to ``TargetVideoPixelFormat/native``.
  public var pixelFormat: TargetVideoPixelFormat
  /// Enable (or disable) physical buffer rotation.
  ///
  /// - When ``FrameOutputOptions/enablePhysicalBufferRotation`` is set to `true`, and
  /// the ``CameraFrameOutput``'s ``CameraFrameOutput/outputOrientation``
  /// is set to any value different than the Camera sensor's native orientation, the Camera pipeline
  /// will physically rotate the buffers to apply the orientation.
  /// The resulting ``Frame``'s ``Frame/orientation``
  /// will then always be ``CameraOrientation/up``, meaning it no longer needs to be rotated by the consumer.
  /// - When ``FrameOutputOptions/enablePhysicalBufferRotation`` is set to `false`, the Camera
  /// pipeline will not physically rotate buffers, but instead only provide the ``Frame``'s
  /// orientation relative to the ``CameraFrameOutput``'s target ``CameraFrameOutput/outputOrientation``
  /// as metadata (see ``Frame/orientation``), meaning the consumers have to
  /// handle orientation themselves - e.g. by reading pixels in a different order, or
  /// applying orientation in a GPU rendering pass, depending on the use-case.
  ///
  /// Setting ``FrameOutputOptions/enablePhysicalBufferRotation`` to `true` introduces
  /// processing overhead.
  /// Defaults to false.
  public var enablePhysicalBufferRotation: Bool
  /// Whether the ``CameraFrameOutput`` attaches a Camera Intrinsic Matrix to the Frames it produces.
  ///
  /// The output enables delivery only when the capture connection supports it. Video stabilization can
  /// prevent intrinsic-matrix delivery.
  ///
  /// See ``Frame/cameraIntrinsicMatrix``. Defaults to `false`.
  public var enableCameraMatrixDelivery: Bool
  /// Whether to drop new Frames when they arrive while the
  /// frame callback is still executing.
  ///
  /// - If set to `true`, the ``CameraFrameOutput`` will
  /// automatically drop any Frames that arrive while your frame callback is still executing to avoid
  /// exhausting resources,
  /// at the risk of losing information since Frames may be dropped.
  /// - If set to `false`, the ``CameraFrameOutput`` will
  /// queue up any Frames that arrive while your frame callback
  /// is still executing and immediately call it once it is free
  /// again, at the risk of exhausting resources and growing RAM.
  ///
  /// Defaults to true.
  public var dropFramesWhileBusy: Bool

  /// Creates frame-output options with native pixel format and late-frame dropping enabled by default.
  ///
  /// - Parameters:
  ///   - targetResolution: The target Frame Resolution to use.
  ///   - enablePreviewSizedOutputBuffers: Deliver smaller, preview-sized output buffers for frame processing.
  ///   - allowDeferredStart: Allow this output to start later in the capture pipeline startup process.
  ///   - pixelFormat: Sets the pixel format of the ``CameraFrameOutput``.
  ///   - enablePhysicalBufferRotation: Enable (or disable) physical buffer rotation.
  ///   - enableCameraMatrixDelivery: Whether the ``CameraFrameOutput`` attaches a Camera Intrinsic Matrix to the Frames it produces.
  ///   - dropFramesWhileBusy: Whether to drop new Frames when they arrive while the frame callback is still executing.
  public init(
    targetResolution: Size = Size(width: 720, height: 1280),
    enablePreviewSizedOutputBuffers: Bool = false,
    allowDeferredStart: Bool = true,
    pixelFormat: TargetVideoPixelFormat = .native,
    enablePhysicalBufferRotation: Bool = false,
    enableCameraMatrixDelivery: Bool = false,
    dropFramesWhileBusy: Bool = true
  ) {
    self.targetResolution = targetResolution
    self.enablePreviewSizedOutputBuffers = enablePreviewSizedOutputBuffers
    self.allowDeferredStart = allowDeferredStart
    self.pixelFormat = pixelFormat
    self.enablePhysicalBufferRotation = enablePhysicalBufferRotation
    self.enableCameraMatrixDelivery = enableCameraMatrixDelivery
    self.dropFramesWhileBusy = dropFramesWhileBusy
  }
}
