// Copyright © 2025 Marc Rousavy @ Margelo

/// Represents a Dynamic Range, often used for recording
/// HDR videos using a ``VideoOutput``.
///
/// To get all available ``DynamicRange``s on a
/// device, use ``CameraDevice/supportedVideoDynamicRanges``.
///
/// To use a specific ``DynamicRange`` in a
/// Camera session, use a ``VideoDynamicRangeConstraint``.
public struct DynamicRange: Equatable, Sendable {
  /// The bit-depth for the dynamic range.
  /// Often 8-bit or 10-bit.
  public var bitDepth: DynamicRangeBitDepth
  /// The color-space for the dynamic range.
  ///
  /// SDR is often composed of ``ColorSpace/srgb`` and ``ColorSpace/p3D65``,
  /// and HDR is often composed of ``ColorSpace/hlgBt2020``.
  public var colorSpace: ColorSpace
  /// The range of YUV color components.
  public var colorRange: ColorRange

  /// Describes a video stream's bit depth, color space, and component range.
  ///
  /// - Parameters:
  ///   - bitDepth: The bit-depth for the dynamic range. Often 8-bit or 10-bit.
  ///   - colorSpace: The color-space for the dynamic range.
  ///   - colorRange: The range of YUV color components.
  public init(
    bitDepth: DynamicRangeBitDepth,
    colorSpace: ColorSpace,
    colorRange: ColorRange
  ) {
    self.bitDepth = bitDepth
    self.colorSpace = colorSpace
    self.colorRange = colorRange
  }
}
