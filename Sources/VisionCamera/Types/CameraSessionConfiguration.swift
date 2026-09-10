// Copyright © 2025 Marc Rousavy @ Margelo

/// Configuration for a ``CameraSession``.
public struct CameraSessionConfiguration: Equatable, Sendable {
  /// Whether audio recording allows haptics and system sounds.
  ///
  /// Haptics can affect stabilization or focus, and sounds may be captured in recordings.
  /// A `nil` value leaves the shared audio-session setting unchanged.
  public var allowsHapticsAndSystemSoundsPlayback: Bool?
  /// Whether AVFoundation mixes recording audio with audio playing in other apps.
  ///
  /// This controls automatic configuration of the app's shared audio session. Other apps' audio may
  /// be captured in the recording. A `nil` value leaves the current setting unchanged.
  @available(iOS 18.0, *)
  public var allowsBackgroundAudioPlayback: Bool? {
    get { backgroundAudioPlayback }
    set { backgroundAudioPlayback = newValue }
  }
  private var backgroundAudioPlayback: Bool?

  /// Creates changes to haptics and system-sound playback during audio recording.
  ///
  /// - Parameter allowsHapticsAndSystemSoundsPlayback: Whether recording allows haptics and system sounds. A `nil` value leaves the current setting unchanged.
  public init(allowsHapticsAndSystemSoundsPlayback: Bool? = nil) {
    self.allowsHapticsAndSystemSoundsPlayback = allowsHapticsAndSystemSoundsPlayback
    self.backgroundAudioPlayback = nil
  }

  /// Creates changes to haptics, system-sound playback, and mixing with other apps' audio.
  ///
  /// - Parameters:
  ///   - allowsHapticsAndSystemSoundsPlayback: Whether recording allows haptics and system sounds. A `nil` value leaves the current setting unchanged.
  ///   - allowsBackgroundAudioPlayback: Whether AVFoundation mixes the shared audio session with other apps. A `nil` value leaves the current setting unchanged.
  @available(iOS 18.0, *)
  public init(
    allowsHapticsAndSystemSoundsPlayback: Bool? = nil,
    allowsBackgroundAudioPlayback: Bool?
  ) {
    self.allowsHapticsAndSystemSoundsPlayback = allowsHapticsAndSystemSoundsPlayback
    self.backgroundAudioPlayback = allowsBackgroundAudioPlayback
  }
}
