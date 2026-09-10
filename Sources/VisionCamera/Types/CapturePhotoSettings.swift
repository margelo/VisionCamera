// Copyright © 2025 Marc Rousavy @ Margelo

import CoreLocation

/// Configuration options for a
/// ``PhotoOutput/capturePhoto(settings:callbacks:)`` call.
///
/// See ``PhotoOutput``
public struct CapturePhotoSettings {
  /// Configures the ``FlashMode`` for this Photo capture.
  ///
  /// On supported devices, AVFoundation uses Retina Flash.
  ///
  /// See ``CameraDevice/hasFlash``. When `nil`, the capture uses its default flash mode, which is off.
  public var flashMode: FlashMode?
  /// Enables or disables the system shutter sound.
  /// The shutter sound is fired exactly when a photo will be captured.
  ///
  /// The OS may choose to override this behaviour, e.g. if
  /// regional sound-suppression settings are applied.
  ///
  /// When `nil`, the capture pipeline keeps its default shutter-sound behavior. Suppression is requested
  /// only on iOS 18 and later when the output supports it. An unsupported suppression request throws.
  public var enableShutterSound: Bool?
  /// Enables or disables depth data delivery in the resulting
  /// ``Photo``.
  ///
  /// Depth data will be embedded in the Photo and can be accessed
  /// via ``Photo/depth``.
  ///
  /// ``CapturePhotoSettings/enableDepthData`` can only be enabled if the
  /// ``PhotoOutput`` supports depth data - see
  /// ``PhotoOutput/supportsDepthDataDelivery``.
  ///
  /// When `nil`, the capture pipeline keeps its default setting.
  ///
  /// Depth delivery also requires a processed photo format and an underlying `AVCapturePhotoOutput`
  /// configured with ``PhotoOutputOptions/enableDepthDataDelivery``. RAW photos cannot include depth data.
  public var enableDepthData: Bool?
  /// Specifies whether red-eye reduction should be applied
  /// automatically on flash captures.
  ///
  /// When ``CapturePhotoSettings/flashMode`` is `off`,
  /// red eye reduction is automatically disabled.
  ///
  /// When `nil`, the capture pipeline keeps its default setting.
  ///
  /// Requesting this feature throws when the capture output does not support it.
  public var enableRedEyeReduction: Bool?
  /// Specifies whether the capture pipeline should
  /// automatically correct lens distortion.
  ///
  /// - Note: If enabled, captured photos will look
  /// slightly different compared to the Preview
  /// because the field-of-view might be narrower.
  ///
  /// When `nil`, the capture pipeline keeps its default setting.
  ///
  /// Requesting this feature throws when the capture output does not support it.
  public var enableDistortionCorrection: Bool?
  /// Enables or disables virtual device image fusion.
  ///
  /// If enabled, the Camera pipeline may capture photos
  /// from multiple constituent physical Camera devices at once
  /// (if using a Camera device that has multiple physical devices)
  /// to improve still image quality.
  ///
  /// RAW photos cannot use virtual device fusion. Requesting fusion for RAW capture throws.
  ///
  /// When `nil`, the capture pipeline keeps its default setting.
  ///
  /// Requesting this feature throws when the capture output does not support it.
  public var enableVirtualDeviceFusion: Bool?
  /// Sets the given `CLLocation` to be embedded
  /// into the EXIF data of the captured ``Photo``.
  ///
  /// Defaults to `nil`.
  public var location: CLLocation?

  /// Creates per-capture Photo settings. Unspecified values use the capture pipeline's defaults.
  ///
  /// - Parameters:
  ///   - flashMode: Configures the ``FlashMode`` for this Photo capture.
  ///   - enableShutterSound: Enables or disables the system shutter sound. The shutter sound is fired exactly when a photo will be captured.
  ///   - enableDepthData: Enables or disables depth data delivery in the resulting ``Photo``.
  ///   - enableRedEyeReduction: Specifies whether red-eye reduction should be applied automatically on flash captures.
  ///   - enableDistortionCorrection: Specifies whether the capture pipeline should automatically correct lens distortion.
  ///   - enableVirtualDeviceFusion: Enables or disables virtual device image fusion.
  ///   - location: Sets the given `CLLocation` to be embedded into the EXIF data of the captured ``Photo``.
  public init(
    flashMode: FlashMode? = nil,
    enableShutterSound: Bool? = nil,
    enableDepthData: Bool? = nil,
    enableRedEyeReduction: Bool? = nil,
    enableDistortionCorrection: Bool? = nil,
    enableVirtualDeviceFusion: Bool? = nil,
    location: CLLocation? = nil
  ) {
    self.flashMode = flashMode
    self.enableShutterSound = enableShutterSound
    self.enableDepthData = enableDepthData
    self.enableRedEyeReduction = enableRedEyeReduction
    self.enableDistortionCorrection = enableDistortionCorrection
    self.enableVirtualDeviceFusion = enableVirtualDeviceFusion
    self.location = location
  }
}
