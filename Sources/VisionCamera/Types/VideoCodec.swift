// Copyright © 2025 Marc Rousavy @ Margelo

/// Represents a video codec for encoded video data.
///
/// H.264 is the most widely supported format. HEVC offers higher compression efficiency. ProRes formats
/// preserve more image information for editing, with larger files and higher bit rates.
public enum VideoCodec: CaseIterable, Sendable {
  /// An unknown codec. It cannot be selected for recording.
  case unknown
  /// Motion JPEG. A legacy format with lower compression efficiency.
  case jpeg
  /// H.264, also known as AVC. The most widely supported video format.
  case h264
  /// H.265, also known as HEVC. Higher compression efficiency than H.264.
  case h265
  /// HEVC with an alpha channel, for content with transparency.
  case h265WithAlpha
  /// ProRes 422 Proxy. The lowest bit rate for proxy editing workflows.
  case proRes422Proxy
  /// ProRes 422 LT. A reduced-bit-rate version of ProRes 422.
  case proRes422Lt
  /// ProRes 422. Standard 4:2:2 quality for editing.
  case proRes422
  /// ProRes 422 HQ. The highest-quality 4:2:2 variant.
  case proRes422Hq
  /// ProRes 4444. Full chroma resolution with optional alpha.
  case proRes4444
  /// ProRes 4444 XQ. The highest-bit-rate non-RAW ProRes variant.
  case proRes4444Xq
  /// ProRes RAW. Compressed Bayer RAW video.
  case proResRaw
  /// ProRes RAW HQ. Higher-quality compressed Bayer RAW video.
  case proResRawHq

}
