import AVFoundation

extension SynchronizedDataFrame {
  public func toSynchronizedFrame() -> SynchronizedFrame {
    switch self.data {
    case .video(let buffer):
      let frame = Frame(buffer: buffer, metadata: metadata)
      return .frame(frame)
    case .depth(let buffer):
      let depth = Depth(depthData: buffer, metadata: metadata)
      return .depth(depth)
    }
  }
}
