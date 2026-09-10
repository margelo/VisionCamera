// Copyright © 2025 Marc Rousavy @ Margelo

/// Configuration for a ``CameraSession``.
public struct CameraSessionConfiguration: Equatable, Sendable {
  /// If enabled, the device may play haptics/vibrations
  /// and system sounds while the ``CameraSession``
  /// is active.
  ///
  /// If disabled, all haptics and system
  /// sounds will be muted while the ``CameraSession``
  /// is active.
  ///
  /// - Note: If ``CameraSessionConfiguration/allowsHapticsAndSystemSoundsPlayback``
  /// is true, haptics or system sounds may also be captured
  /// in Video recordings.
  /// Haptics may also affect stabilization or focus operations.
  ///
  /// When `nil`, the current AVFoundation setting is left unchanged.
  public var allowsHapticsAndSystemSoundsPlayback: Bool?
  /// If enabled, the device may play background audio,
  /// possibly from another app (e.g. Apple Music) while
  /// the ``CameraSession`` is active.
  ///
  /// If disabled, any playing audio will be
  /// stopped while the ``CameraSession`` is active.
  ///
  /// - Note: If ``CameraSessionConfiguration/allowsBackgroundAudioPlayback`` is true,
  /// background audio may also be captured in Video recordings.
  ///
  /// When `nil`, the current AVFoundation setting is left unchanged.
  ///
  /// This option is applied on iOS 18 and later.
  public var allowsBackgroundAudioPlayback: Bool?

  /// Creates the audio-playback configuration for a Camera session.
  ///
  /// - Parameters:
  ///   - allowsHapticsAndSystemSoundsPlayback: If enabled, the device may play haptics/vibrations and system sounds while the ``CameraSession`` is active.
  ///   - allowsBackgroundAudioPlayback: If enabled, the device may play background audio, possibly from another app (e.g. Apple Music) while the ``CameraSession`` is active.
  public init(
    allowsHapticsAndSystemSoundsPlayback: Bool? = nil,
    allowsBackgroundAudioPlayback: Bool? = nil
  ) {
    self.allowsHapticsAndSystemSoundsPlayback = allowsHapticsAndSystemSoundsPlayback
    self.allowsBackgroundAudioPlayback = allowsBackgroundAudioPlayback
  }
}
