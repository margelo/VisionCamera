// Copyright © 2025 Marc Rousavy @ Margelo

public enum PixelFormat: CaseIterable, Sendable {
  case unknown
  case yuv4208BitVideo
  case yuv4208BitFull
  case yuv42010BitVideo
  case yuv42010BitFull
  case yuv4228BitVideo
  case yuv4228BitFull
  case yuv42210BitVideo
  case yuv42210BitFull
  case yuv4448BitVideo
  case yuv4448BitFull
  case rgbBgra8Bit
  case rgbRgba8Bit
  case rgbRgb8Bit
  case rawBayerPacked9612Bit
  case rawBayerUnpacked16Bit
  case depth16Bit
  case depth32Bit
  case depthPointCloud32Bit
  case disparity16Bit
  case disparity32Bit
  case `private`
}
