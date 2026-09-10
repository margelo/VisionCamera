// Copyright © 2025 Marc Rousavy @ Margelo

public enum TargetDynamicRangeBitDepth: String, CaseIterable, Sendable {
  case sdr8Bit = "sdr-8-bit"
  case hdr10Bit = "hdr-10-bit"

  public var stringValue: String {
    rawValue
  }

  public init?(fromString string: String) {
    self.init(rawValue: string)
  }
}
