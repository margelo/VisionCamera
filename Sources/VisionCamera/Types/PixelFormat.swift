// Copyright © 2025 Marc Rousavy @ Margelo

/// Represents any kind of pixel format for a media sample.
///
/// Video formats contain YUV, RGB, or RAW Bayer samples. Depth and disparity formats describe distance or
/// pixel shift. A private format has an implementation-defined layout and may only allow GPU access.
public enum PixelFormat: CaseIterable, Sendable {
  /// The pixel format is unknown.
  case unknown
  /// YUV 4:2:0 samples with 8 bits per component and limited video range.
  case yuv4208BitVideo
  /// YUV 4:2:0 samples with 8 bits per component and full range.
  case yuv4208BitFull
  /// YUV 4:2:0 samples with 10 bits per component and limited video range.
  case yuv42010BitVideo
  /// YUV 4:2:0 samples with 10 bits per component and full range.
  case yuv42010BitFull
  /// YUV 4:2:2 samples with 8 bits per component and limited video range.
  case yuv4228BitVideo
  /// YUV 4:2:2 samples with 8 bits per component and full range.
  case yuv4228BitFull
  /// YUV 4:2:2 samples with 10 bits per component and limited video range.
  case yuv42210BitVideo
  /// YUV 4:2:2 samples with 10 bits per component and full range.
  case yuv42210BitFull
  /// YUV 4:4:4 samples with 8 bits per component and limited video range.
  case yuv4448BitVideo
  /// YUV 4:4:4 samples with 8 bits per component and full range.
  case yuv4448BitFull
  /// Interleaved blue, green, red, and alpha channels with 8 bits per channel.
  case rgbBgra8Bit
  /// Interleaved red, green, blue, and alpha channels with 8 bits per channel.
  case rgbRgba8Bit
  /// Interleaved red, green, and blue channels with 8 bits per channel.
  case rgbRgb8Bit
  /// Packed96 Bayer RAW sensor samples with 12 bits per sample.
  case rawBayerPacked9612Bit
  /// Unpacked Bayer RAW sensor samples stored in 16-bit values.
  case rawBayerUnpacked16Bit
  /// Depth values stored as 16-bit floating-point samples.
  case depth16Bit
  /// Depth values stored as 32-bit floating-point samples.
  case depth32Bit
  /// Interleaved 32-bit floating-point point-cloud samples containing x, y, z, and confidence. This layout
  /// is not supported by the iOS pixel-format converter.
  case depthPointCloud32Bit
  /// Disparity values stored as 16-bit floating-point samples.
  case disparity16Bit
  /// Disparity values stored as 32-bit floating-point samples.
  case disparity32Bit
  /// An implementation-defined private format that may only allow GPU access.
  case `private`

}
