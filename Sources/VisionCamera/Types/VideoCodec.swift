// Copyright © 2025 Marc Rousavy @ Margelo

public enum VideoCodec: String, CaseIterable, Sendable {
  case unknown
  case jpeg
  case h264
  case h265
  case h265WithAlpha = "h265-with-alpha"
  case proRes422Proxy = "pro-res-422-proxy"
  case proRes422Lt = "pro-res-422-lt"
  case proRes422 = "pro-res-422"
  case proRes422Hq = "pro-res-422-hq"
  case proRes4444 = "pro-res-4444"
  case proRes4444Xq = "pro-res-4444-xq"
  case proResRaw = "pro-res-raw"
  case proResRawHq = "pro-res-raw-hq"

  public var stringValue: String {
    rawValue
  }

  public init?(fromString string: String) {
    self.init(rawValue: string)
  }
}
