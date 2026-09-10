// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation

extension VideoOutputOptions {
  func validateBitRate(for codec: AVVideoCodecType?) throws {
    guard let targetBitRate else { return }
    guard targetBitRate > 0 else {
      throw CameraError(message: "The target video bit rate must be positive.")
    }
    let proResCodecs: [AVVideoCodecType] = [.proRes422Proxy, .proRes422LT, .proRes422, .proRes422HQ, .proRes4444]
    var isProRes = codec.map(proResCodecs.contains) ?? false
    if #available(iOS 18.0, *) { isProRes = isProRes || codec == .appleProRes4444XQ }
    if #available(iOS 26.0, *) { isProRes = isProRes || codec == .proResRAW || codec == .proResRAWHQ }
    guard !isProRes else {
      throw CameraError(message: "ProRes codecs control their own bit rate. Choose a ProRes variant instead.")
    }
  }
}
