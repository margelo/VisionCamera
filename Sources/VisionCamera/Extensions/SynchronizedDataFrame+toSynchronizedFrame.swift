import AVFoundation

extension SynchronizedDataFrame {
  /// Wraps each retained native sample in a synchronized frame.
  func toSynchronizedFrame() -> SynchronizedFrame {
    switch self.data {
    case .video(let buffer):
      let frame = Frame(buffer: buffer, metadata: metadata)
      return .frame(frame)
    case .audio(let buffer):
      return .audio(buffer)
    case .depth(let buffer):
      let depth = Depth(depthData: buffer, metadata: metadata)
      return .depth(depth)
    case .metadata(let objects):
      return .metadata(objects: objects.map { ObjectOutput.scannedObject(from: $0) }, timestamp: metadata.timestamp)
    }
  }
}
