// Copyright © 2025 Marc Rousavy @ Margelo

public enum DepthPixelFormat: CaseIterable, Sendable {
  case unknown
  case depth16Bit
  case depth32Bit
  case depthPointCloud32Bit
  case disparity16Bit
  case disparity32Bit
}
