// Copyright © 2025 Marc Rousavy @ Margelo

/// Configuration options for a ``VideoOutput``.
///
/// See ``VideoOutput``
public struct VideoOutputOptions: Equatable, Sendable {
  /// The target Video Resolution to use.
  ///
  /// To include this output's ``VideoOutputOptions/targetResolution`` in
  /// ``CameraSession`` format negotiation, add a ``ResolutionBiasConstraint``
  /// for this output. The session will negotiate it with constraints (such
  /// as HDR, FPS, etc) in a ``CameraSessionConfig`` to
  /// finalize the Resolution used for the Output.
  /// Append resolution biases after explicit constraints when they should have lower priority.
  /// This is therefore merely a resolution _target_, and may
  /// not be exactly met.
  ///
  /// If the given ``VideoOutputOptions/targetResolution`` cannot be met
  /// exactly, its aspect ratio (computed by
  /// ``Size/width`` / ``Size/height``) will
  /// be prioritized over pixel count.
  ///
  /// Defaults to 1080 by 1920 pixels.
  public var targetResolution: Size
  /// Whether to enable, or disable audio in video
  /// recordings.
  /// By default, no audio is recorded.
  ///
  /// This requires audio/microphone permission.
  ///
  /// Defaults to false.
  public var enableAudio: Bool?
  /// Specifies the target bit-rate for the
  /// ``VideoOutput``, in bits per second.
  ///
  /// The encoder may or may not encode with exactly this bit-rate,
  /// depending on system pressure, moving pixels, and file size
  /// constraints - but it will be taken as reference.
  ///
  /// Defaults to `nil`.
  public var targetBitRate: Double?
  /// The container file type for recordings produced by this output.
  ///
  /// When `nil`, recordings use ``RecorderFileType/mov``.
  public var fileType: RecorderFileType?

  /// Creates video-output options with a Full HD target resolution.
  ///
  /// - Parameters:
  ///   - targetResolution: The target Video Resolution to use.
  ///   - enableAudio: Whether to enable, or disable audio in video recordings. By default, no audio is recorded.
  ///   - targetBitRate: Specifies the target bit-rate for the ``VideoOutput``, in bits per second.
  ///   - fileType: The container file type for recordings produced by this output.
  public init(
    targetResolution: Size = Size(width: 1080, height: 1920),
    enableAudio: Bool? = nil,
    targetBitRate: Double? = nil,
    fileType: RecorderFileType? = nil
  ) {
    self.targetResolution = targetResolution
    self.enableAudio = enableAudio
    self.targetBitRate = targetBitRate
    self.fileType = fileType
  }
}
