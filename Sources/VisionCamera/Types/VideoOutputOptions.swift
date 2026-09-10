// Copyright © 2025 Marc Rousavy @ Margelo

import CoreGraphics

/// Configuration options for a ``VideoOutput``.
///
/// See ``VideoOutput``
public struct VideoOutputOptions: Equatable, Sendable {
  /// The target Video Resolution to use.
  ///
  /// To include this output's ``VideoOutputOptions/targetResolution`` in
  /// ``CameraSession`` format negotiation, add a ``Constraint/resolution(_:)``
  /// for this output. The session will negotiate it with constraints (such
  /// as HDR, FPS, etc) in a ``CameraSessionConfig`` to
  /// finalize the Resolution used for the Output.
  /// Append resolution biases after explicit constraints when they should have lower priority.
  /// This is therefore merely a resolution _target_, and may
  /// not be exactly met.
  ///
  /// If the given ``VideoOutputOptions/targetResolution`` cannot be met
  /// exactly, its aspect ratio (computed by
  /// `CGSize.width` / `CGSize.height`) will
  /// be prioritized over pixel count.
  ///
  /// Defaults to 1080 by 1920 pixels.
  public var targetResolution: CGSize
  /// Whether to enable, or disable audio in video
  /// recordings.
  /// By default, no audio is recorded.
  ///
  /// This requires audio/microphone permission.
  ///
  /// Defaults to false.
  public var isAudioEnabled: Bool
  /// Specifies the target bit-rate for the
  /// ``VideoOutput``, in positive whole bits per second.
  ///
  /// ProRes codecs control their own bit rate; requesting a custom bit rate with ProRes throws.
  ///
  /// The encoder may or may not encode with exactly this bit-rate,
  /// depending on system pressure, moving pixels, and file size
  /// constraints - but it will be taken as reference.
  ///
  /// Defaults to `nil`.
  public var bitRate: Int?
  /// Creates video-output options with a Full HD target resolution.
  ///
  /// - Parameters:
  ///   - targetResolution: The target Video Resolution to use.
  ///   - isAudioEnabled: Whether to enable, or disable audio in video recordings. By default, no audio is recorded.
  ///   - bitRate: Specifies the target bit-rate for the ``VideoOutput``, in bits per second.
  public init(
    targetResolution: CGSize = CGSize(width: 1080, height: 1920),
    isAudioEnabled: Bool = false,
    bitRate: Int? = nil
  ) {
    self.targetResolution = targetResolution
    self.isAudioEnabled = isAudioEnabled
    self.bitRate = bitRate
  }
}
