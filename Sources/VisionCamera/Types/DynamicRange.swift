// Copyright © 2025 Marc Rousavy @ Margelo

public struct DynamicRange: Equatable, Sendable {
  public var bitDepth: DynamicRangeBitDepth
  public var colorSpace: ColorSpace
  public var colorRange: ColorRange

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
