// Copyright © 2025 Marc Rousavy @ Margelo

/// Specifies options for configuring a ``CameraController``.
///
/// Setting a value to `nil` leaves the current device setting unchanged.
public struct CameraControllerConfiguration: Equatable, Sendable {
  /// Low light boost allows the Camera pipeline to automatically
  /// extend exposure times (and effectively drop frame rate) to
  /// receive more light, if necessary.
  ///
  /// Applying this configuration throws if the ``CameraDevice`` does not support low-light-boost -
  /// see ``CameraDevice/supportsLowLightBoost``.
  /// A `nil` value leaves the current setting unchanged.
  public var enableLowLightBoost: Bool?
  /// If set to `true`, auto-focus will switch between
  /// focus states much slower and smoother to appear
  /// less intrusive in video recordings.
  ///
  /// Applying this configuration throws if the ``CameraDevice`` does not support
  /// smooth auto focus - see ``CameraDevice/supportsSmoothAutoFocus``.
  ///
  /// A `nil` value leaves the current setting unchanged.
  public var enableSmoothAutoFocus: Bool?
  /// If set to `true`, the Camera pipeline may correct
  /// areas of the image that may appear distorted - for
  /// example the edges of a ultra-wide-angle camera,
  /// at the cost of losing a small amount of field of view.
  ///
  /// When ``CameraControllerConfiguration/enableDistortionCorrection`` is enabled
  /// and the Camera pipeline applies a crop around the edges,
  /// the images will be upscaled to compensate for the artificial
  /// zoom - set ``CameraControllerConfiguration/enableDistortionCorrection`` to `false`
  /// if you want to avoid this overhead.
  ///
  /// Applying this configuration throws if the ``CameraDevice`` does not support distortion
  /// correction - see ``CameraDevice/supportsDistortionCorrection``.
  ///
  /// A `nil` value leaves the current setting unchanged.
  public var enableDistortionCorrection: Bool?

  /// Creates a set of device-setting changes, leaving unspecified settings unchanged.
  ///
  /// - Parameters:
  ///   - enableLowLightBoost: Low light boost allows the Camera pipeline to automatically extend exposure times (and effectively drop frame rate) to receive more light, if necessary.
  ///   - enableSmoothAutoFocus: If set to `true`, auto-focus will switch between focus states much slower and smoother to appear less intrusive in video recordings.
  ///   - enableDistortionCorrection: If set to `true`, the Camera pipeline may correct areas of the image that may appear distorted - for example the edges of a ultra-wide-angle camera, at the cost of losing a small amount of field of view.
  public init(
    enableLowLightBoost: Bool? = nil,
    enableSmoothAutoFocus: Bool? = nil,
    enableDistortionCorrection: Bool? = nil
  ) {
    self.enableLowLightBoost = enableLowLightBoost
    self.enableSmoothAutoFocus = enableSmoothAutoFocus
    self.enableDistortionCorrection = enableDistortionCorrection
  }
}
