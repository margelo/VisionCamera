// Copyright © 2025 Marc Rousavy @ Margelo

/// The media stream whose resolution participates in Camera format negotiation.
public enum StreamType: Sendable {
  /// A video Frame stream.
  case video
  /// A still Photo stream.
  case photo
  /// A depth Frame stream.
  case depthVideo
  /// Depth data delivered with a Photo.
  case depthPhoto
}
