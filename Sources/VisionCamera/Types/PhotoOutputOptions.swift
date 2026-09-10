// Copyright © 2025 Marc Rousavy @ Margelo

import CoreGraphics

/// Configuration options for a ``PhotoOutput``.
///
/// See ``PhotoOutput``
public struct PhotoOutputOptions: Equatable, Sendable {
  /// The target Photo Resolution to use.
  ///
  /// To include this output's ``PhotoOutputOptions/targetResolution`` in
  /// ``CameraSession`` format negotiation, add a ``Constraint/resolution(_:)``
  /// for this output. The session will negotiate it with constraints (such
  /// as HDR, FPS, etc) in a ``CameraSessionConfig`` to
  /// finalize the Resolution used for the Output.
  /// Append resolution biases after explicit constraints when they should have lower priority.
  /// This is therefore merely a resolution _target_, and may
  /// not be exactly met.
  ///
  /// If the given ``PhotoOutputOptions/targetResolution`` cannot be met
  /// exactly, its aspect ratio (computed by
  /// `CGSize.width` / `CGSize.height`) will
  /// be prioritized over pixel count.
  ///
  /// Defaults to 3024 by 4032 pixels.
  public var targetResolution: CGSize
  /// Specifies the ``TargetPhotoContainerFormat`` to
  /// shoot the ``Photo`` in.
  ///
  /// Defaults to ``TargetPhotoContainerFormat/automatic(quality:)``.
  public var containerFormat: TargetPhotoContainerFormat
  /// Specifies the balance between speed and image quality for the photo capture pipeline.
  ///
  /// Use ``QualityPrioritization/speed`` to minimize capture latency, ``QualityPrioritization/balanced`` to
  /// balance latency with quality, or ``QualityPrioritization/quality`` to allow more processing time.
  ///
  /// When `nil`, keeps balanced prioritization for processed photos and uses the required speed prioritization for Bayer RAW.
  /// Explicit values unsupported by the selected RAW format throw during capture.
  public var qualityPrioritization: QualityPrioritization?
  /// Configures the capture pipeline to deliver depth data with processed photos.
  ///
  /// The session selects a depth-capable format. Request depth for individual captures with
  /// ``CapturePhotoSettings/isDepthDataEnabled``. RAW capture cannot deliver depth data.
  public var isDepthDataDeliveryEnabled: Bool
  /// When this is set to a specific `CGSize`,
  /// a ready to display `UIImage` is delivered with the processed Photo when the capture pipeline supplies a
  /// preview image.
  ///
  /// Preview Image delivery requires additional processing,
  /// so this is disabled by default.
  ///
  /// If this is `nil` (the default), no preview Image
  /// will be supplied.
  ///
  /// It is recommended to set this to a `CGSize`
  /// that is as low as possible to avoid unnecessary overhead.
  ///
  /// See ``CapturePhotoCallbacks/didReceivePreviewImage``
  /// Defaults to `nil`.
  public var previewImageTargetSize: CGSize?

  /// Creates photo-output options with automatic processed-format selection.
  ///
  /// - Parameters:
  ///   - targetResolution: The target Photo Resolution to use.
  ///   - containerFormat: Specifies the ``TargetPhotoContainerFormat`` to shoot the ``Photo`` in.
  ///   - qualityPrioritization: Specifies the balance between speed and image quality for the photo capture pipeline.
  ///   - isDepthDataDeliveryEnabled: Configures the session for depth photo delivery.
  ///   - previewImageTargetSize: When this is set to a specific `CGSize`, a ready to display `UIImage` is delivered with the processed Photo when the capture pipeline supplies a preview image.
  public init(
    targetResolution: CGSize = CGSize(width: 3024, height: 4032),
    containerFormat: TargetPhotoContainerFormat = .automatic(),
    qualityPrioritization: QualityPrioritization? = nil,
    isDepthDataDeliveryEnabled: Bool = false,
    previewImageTargetSize: CGSize? = nil
  ) {
    self.targetResolution = targetResolution
    self.containerFormat = containerFormat
    self.qualityPrioritization = qualityPrioritization
    self.isDepthDataDeliveryEnabled = isDepthDataDeliveryEnabled
    self.previewImageTargetSize = previewImageTargetSize
  }
}
