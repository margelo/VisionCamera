// Copyright © 2025 Marc Rousavy @ Margelo

public enum PixelFormat: String, CaseIterable, Sendable {
  case unknown
  case yuv4208BitVideo = "yuv-420-8-bit-video"
  case yuv4208BitFull = "yuv-420-8-bit-full"
  case yuv42010BitVideo = "yuv-420-10-bit-video"
  case yuv42010BitFull = "yuv-420-10-bit-full"
  case yuv4228BitVideo = "yuv-422-8-bit-video"
  case yuv4228BitFull = "yuv-422-8-bit-full"
  case yuv42210BitVideo = "yuv-422-10-bit-video"
  case yuv42210BitFull = "yuv-422-10-bit-full"
  case yuv4448BitVideo = "yuv-444-8-bit-video"
  case yuv4448BitFull = "yuv-444-8-bit-full"
  case rgbBgra8Bit = "rgb-bgra-8-bit"
  case rgbRgba8Bit = "rgb-rgba-8-bit"
  case rgbRgb8Bit = "rgb-rgb-8-bit"
  case rawBayerPacked9612Bit = "raw-bayer-packed96-12-bit"
  case rawBayerUnpacked16Bit = "raw-bayer-unpacked-16-bit"
  case depth16Bit = "depth-16-bit"
  case depth32Bit = "depth-32-bit"
  case depthPointCloud32Bit = "depth-point-cloud-32-bit"
  case disparity16Bit = "disparity-16-bit"
  case disparity32Bit = "disparity-32-bit"
  case `private`

  public var stringValue: String {
    rawValue
  }

  public init?(fromString string: String) {
    self.init(rawValue: string)
  }
}
