// Copyright © 2025 Marc Rousavy @ Margelo

import CoreVideo

/// Represents any kind of pixel format for a media sample.
///
/// Video formats contain YUV, RGB, or RAW Bayer samples. Depth and disparity formats describe distance or
/// pixel shift. Each value preserves its exact Core Video pixel format identifier, including compressed
/// and future formats. A format identifier does not imply that a particular output can produce it.
public struct PixelFormat: RawRepresentable, Hashable, Sendable {
  /// The exact Core Video pixel format identifier.
  public let rawValue: OSType

  /// Creates a pixel format from a Core Video identifier without changing its layout or compression.
  public init(rawValue: OSType) {
    self.rawValue = rawValue
  }

  /// No pixel format is available, for example after a Frame is disposed.
  public static let unknown = PixelFormat(rawValue: 0)
  /// YUV 4:2:0 samples with 8 bits per component and limited video range.
  public static let yuv4208BitVideo = PixelFormat(rawValue: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)
  /// YUV 4:2:0 samples with 8 bits per component and full range.
  public static let yuv4208BitFull = PixelFormat(rawValue: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
  /// YUV 4:2:0 samples with 10 bits per component and limited video range.
  public static let yuv42010BitVideo = PixelFormat(rawValue: kCVPixelFormatType_420YpCbCr10BiPlanarVideoRange)
  /// YUV 4:2:0 samples with 10 bits per component and full range.
  public static let yuv42010BitFull = PixelFormat(rawValue: kCVPixelFormatType_420YpCbCr10BiPlanarFullRange)
  /// YUV 4:2:2 samples with 8 bits per component and limited video range.
  public static let yuv4228BitVideo = PixelFormat(rawValue: kCVPixelFormatType_422YpCbCr8BiPlanarVideoRange)
  /// YUV 4:2:2 samples with 8 bits per component and full range.
  public static let yuv4228BitFull = PixelFormat(rawValue: kCVPixelFormatType_422YpCbCr8BiPlanarFullRange)
  /// YUV 4:2:2 samples with 10 bits per component and limited video range.
  public static let yuv42210BitVideo = PixelFormat(rawValue: kCVPixelFormatType_422YpCbCr10BiPlanarVideoRange)
  /// YUV 4:2:2 samples with 10 bits per component and full range.
  public static let yuv42210BitFull = PixelFormat(rawValue: kCVPixelFormatType_422YpCbCr10BiPlanarFullRange)
  /// YUV 4:4:4 samples with 8 bits per component and limited video range.
  public static let yuv4448BitVideo = PixelFormat(rawValue: kCVPixelFormatType_444YpCbCr8BiPlanarVideoRange)
  /// YUV 4:4:4 samples with 8 bits per component and full range.
  public static let yuv4448BitFull = PixelFormat(rawValue: kCVPixelFormatType_444YpCbCr8BiPlanarFullRange)
  /// Interleaved blue, green, red, and alpha channels with 8 bits per channel.
  public static let rgbBgra8Bit = PixelFormat(rawValue: kCVPixelFormatType_32BGRA)
  /// Interleaved red, green, blue, and alpha channels with 8 bits per channel.
  public static let rgbRgba8Bit = PixelFormat(rawValue: kCVPixelFormatType_32RGBA)
  /// Interleaved red, green, and blue channels with 8 bits per channel.
  public static let rgbRgb8Bit = PixelFormat(rawValue: kCVPixelFormatType_24RGB)
  /// Packed96 Bayer RAW sensor samples with 12 bits per sample.
  public static let rawBayerPacked9612Bit = PixelFormat(rawValue: kCVPixelFormatType_96VersatileBayerPacked12)
  /// Unpacked Bayer RAW sensor samples stored in 16-bit values.
  public static let rawBayerUnpacked16Bit = PixelFormat(rawValue: kCVPixelFormatType_16VersatileBayer)
  /// Depth values stored as 16-bit floating-point samples.
  public static let depth16Bit = PixelFormat(rawValue: kCVPixelFormatType_DepthFloat16)
  /// Depth values stored as 32-bit floating-point samples.
  public static let depth32Bit = PixelFormat(rawValue: kCVPixelFormatType_DepthFloat32)
  /// Disparity values stored as 16-bit floating-point samples.
  public static let disparity16Bit = PixelFormat(rawValue: kCVPixelFormatType_DisparityFloat16)
  /// Disparity values stored as 32-bit floating-point samples.
  public static let disparity32Bit = PixelFormat(rawValue: kCVPixelFormatType_DisparityFloat32)

}
