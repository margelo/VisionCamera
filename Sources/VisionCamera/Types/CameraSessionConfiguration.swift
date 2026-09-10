// Copyright © 2025 Marc Rousavy @ Margelo

public struct CameraSessionConfiguration: Equatable, Sendable {
  public var allowHapticsAndSystemSoundsPlayback: Bool?
  public var allowBackgroundAudioPlayback: Bool?

  public init(
    allowHapticsAndSystemSoundsPlayback: Bool? = nil,
    allowBackgroundAudioPlayback: Bool? = nil
  ) {
    self.allowHapticsAndSystemSoundsPlayback = allowHapticsAndSystemSoundsPlayback
    self.allowBackgroundAudioPlayback = allowBackgroundAudioPlayback
  }
}
