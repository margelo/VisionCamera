// Copyright © 2025 Marc Rousavy @ Margelo

/// Represents a target ``DynamicRange``, for
/// example to be used with the Constraints API.
///
/// See ``Constraint``
public struct TargetDynamicRange: Equatable, Sendable {
  /// The target bit depth, either 8-bit or 10-bit.
  public var bitDepth: TargetDynamicRangeBitDepth
  /// The color space to request for the video stream.
  public var colorSpace: TargetColorSpace
  /// The target range of YUV color components.
  public var colorRange: TargetColorRange

  /// Specifies the bit depth, color space, and component range to request during negotiation.
  ///
  /// - Parameters:
  ///   - bitDepth: The target bit depth, either 8-bit or 10-bit.
  ///   - colorSpace: The color space to request for the video stream.
  ///   - colorRange: The target range of YUV color components.
  public init(
    bitDepth: TargetDynamicRangeBitDepth,
    colorSpace: TargetColorSpace,
    colorRange: TargetColorRange
  ) {
    self.bitDepth = bitDepth
    self.colorSpace = colorSpace
    self.colorRange = colorRange
  }
}
