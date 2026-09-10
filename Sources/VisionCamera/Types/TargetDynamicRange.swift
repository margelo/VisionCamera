// Copyright © 2025 Marc Rousavy @ Margelo

public struct TargetDynamicRange: Equatable, Sendable {
  public var bitDepth: TargetDynamicRangeBitDepth
  public var colorSpace: TargetColorSpace
  public var colorRange: TargetColorRange

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
