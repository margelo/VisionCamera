// Copyright © 2025 Marc Rousavy @ Margelo

public struct VideoOutputSettings: Equatable, Sendable {
  public var codec: VideoCodec?

  public init(
    codec: VideoCodec? = nil
  ) {
    self.codec = codec
  }
}
