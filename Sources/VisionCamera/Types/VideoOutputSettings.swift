// Copyright © 2025 Marc Rousavy @ Margelo

/// Output settings for a ``VideoOutput``.
///
/// See ``VideoOutput``
/// See ``VideoOutput/setOutputSettings(settings:)``
public struct VideoOutputSettings: Equatable, Sendable {
  /// Configures the ``VideoCodec`` to use for recording a video.
  ///
  /// When `nil`, no codec change is applied. A newly created output uses the native capture pipeline's
  /// recommended settings.
  public var codec: VideoCodec?

  /// Selects output settings to apply before creating a video recorder.
  ///
  /// - Parameters:
  ///   - codec: Configures the ``VideoCodec`` to use for recording a video.
  public init(
    codec: VideoCodec? = nil
  ) {
    self.codec = codec
  }
}
