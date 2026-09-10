import AVFoundation

extension SynchronizedDataFrame {
  /// Wraps the retained video or depth sample and its metadata in a synchronized frame.
  var synchronizedFrame: SynchronizedFrame {
    switch self.data {
    case .video(let buffer):
      let frame = Frame(sampleBuffer: buffer, metadata: metadata)
      return .frame(frame)
    case .depth(let buffer):
      let depth = Depth(depthData: buffer, metadata: metadata)
      return .depth(depth)
    }
  }
}
