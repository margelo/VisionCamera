// Copyright © 2025 Marc Rousavy @ Margelo

/// Represents the type of a media sample.
/// - ``MediaType/video``: A pixel-based format suitable for recordings, each pixel contains a color.
/// - ``MediaType/depth``: A pixel-based depth or disparity map, each pixel is a physical distance.
/// - ``MediaType/metadata``: An object-based format, like QR codes.
/// - ``MediaType/other``: An unknown media format.
public enum MediaType: CaseIterable, Sendable {
  /// A pixel-based format suitable for recordings, each pixel contains a color.
  case video
  /// A pixel-based depth or disparity map, each pixel is a physical distance.
  case depth
  /// An object-based format, like QR codes.
  case metadata
  /// An unknown media format.
  case other

}
