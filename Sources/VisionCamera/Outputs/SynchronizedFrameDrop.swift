// Copyright © 2025 Marc Rousavy @ Margelo

/// A frame that could not be delivered with its synchronized samples.
public struct SynchronizedFrameDrop: Equatable, Sendable {
  /// The media type of the dropped sample.
  public let mediaType: MediaType
  /// Why AVFoundation dropped the sample.
  public let reason: FrameDroppedReason

  /// Describes a dropped sample from a synchronized output.
  /// - Parameters:
  ///   - mediaType: The media type of the dropped sample.
  ///   - reason: Why AVFoundation dropped the sample.
  public init(mediaType: MediaType, reason: FrameDroppedReason) {
    self.mediaType = mediaType
    self.reason = reason
  }
}
