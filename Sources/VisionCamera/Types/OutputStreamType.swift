// Copyright © 2025 Marc Rousavy @ Margelo

/// Represents the type of an output stream,
/// often related to ``CameraOutput``.
///
/// This is used for getting available resolutions for a given
/// ``OutputStreamType`` via
/// ``CameraDevice/supportedResolutions(for:)``
public enum OutputStreamType: CaseIterable, Sendable {
  /// A recorded video stream.
  case video
  /// A still-photo output.
  case photo
  /// A live stream of video frames.
  case stream
  /// Depth data associated with a still photo.
  case depthPhoto
  /// A live stream of depth frames.
  case depthStream

}
