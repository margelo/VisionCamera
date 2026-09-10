// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation

/// Represents the type of a media sample.
/// - ``MediaType/video``: A pixel-based format suitable for recordings, each pixel contains a color.
/// - ``MediaType/depth``: A pixel-based depth or disparity map, each pixel is a physical distance.
/// - ``MediaType/metadata``: An object-based format, like QR codes.
/// Native media types outside these categories retain their AVFoundation identifier.
public enum MediaType: Hashable, Sendable {
  /// A pixel-based format suitable for recordings, each pixel contains a color.
  case video
  /// A pixel-based depth or disparity map, each pixel is a physical distance.
  case depth
  /// An object-based format, like QR codes.
  case metadata
  /// Another native media type, preserved for custom capture outputs.
  case other(AVMediaType)

}
