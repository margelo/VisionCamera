// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation

extension VideoOutputOptions {
  func validateBitRate(for codec: AVVideoCodecType?) throws {
    guard let bitRate else { return }
    guard bitRate > 0 else {
      throw RecordingError.invalidBitRate
    }
    let proResCodecs: [AVVideoCodecType] = [.proRes422Proxy, .proRes422LT, .proRes422, .proRes422HQ, .proRes4444]
    var isProRes = codec.map(proResCodecs.contains) ?? false
    if #available(iOS 18.0, *) { isProRes = isProRes || codec == .appleProRes4444XQ }
    if #available(iOS 26.0, *) { isProRes = isProRes || codec == .proResRAW || codec == .proResRAWHQ }
    guard !isProRes else {
      throw RecordingError.proResBitRateUnsupported
    }
  }
}
