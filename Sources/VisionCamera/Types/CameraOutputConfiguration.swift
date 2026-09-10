// Copyright © 2025 Marc Rousavy @ Margelo

public struct CameraOutputConfiguration {
  public var mirrorMode: MirrorMode
  public var output: any CameraOutput

  public init(
    mirrorMode: MirrorMode = .auto,
    output: any CameraOutput
  ) {
    self.mirrorMode = mirrorMode
    self.output = output
  }
}
