// Copyright © 2025 Marc Rousavy @ Margelo

public enum DepthPixelFormat: String, CaseIterable, Sendable {
  case unknown
  case depth16Bit = "depth-16-bit"
  case depth32Bit = "depth-32-bit"
  case depthPointCloud32Bit = "depth-point-cloud-32-bit"
  case disparity16Bit = "disparity-16-bit"
  case disparity32Bit = "disparity-32-bit"

  public var stringValue: String {
    rawValue
  }

  public init?(fromString string: String) {
    self.init(rawValue: string)
  }
}
