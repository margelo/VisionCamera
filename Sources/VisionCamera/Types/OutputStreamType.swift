// Copyright © 2025 Marc Rousavy @ Margelo

public enum OutputStreamType: String, CaseIterable, Sendable {
  case video
  case photo
  case stream
  case depthPhoto = "depth-photo"
  case depthStream = "depth-stream"

  public var stringValue: String {
    rawValue
  }

  public init?(fromString string: String) {
    self.init(rawValue: string)
  }
}
