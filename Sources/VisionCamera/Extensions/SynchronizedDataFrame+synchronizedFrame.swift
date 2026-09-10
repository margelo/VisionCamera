import AVFoundation

extension SynchronizedDataFrame {
  /// Wraps the retained video or depth sample and its metadata in a synchronized frame.
  var synchronizedFrame: SynchronizedFrame {
    switch self.data {
    case .video(let buffer):
      let frame = Frame(sampleBuffer: buffer, metadata: metadata)
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
