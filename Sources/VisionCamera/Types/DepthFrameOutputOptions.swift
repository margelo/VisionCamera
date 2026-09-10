// Copyright © 2025 Marc Rousavy @ Margelo

public struct DepthFrameOutputOptions: Equatable, Sendable {
  public var enableFiltering: Bool
  public var targetResolution: Size
  public var enablePhysicalBufferRotation: Bool
  public var dropFramesWhileBusy: Bool
  public var allowDeferredStart: Bool

  public init(
    enableFiltering: Bool = true,
    targetResolution: Size = Size(width: 480, height: 854),
    enablePhysicalBufferRotation: Bool = false,
    dropFramesWhileBusy: Bool = true,
    allowDeferredStart: Bool = true
  ) {
    self.enableFiltering = enableFiltering
    self.targetResolution = targetResolution
    self.enablePhysicalBufferRotation = enablePhysicalBufferRotation
    self.dropFramesWhileBusy = dropFramesWhileBusy
    self.allowDeferredStart = allowDeferredStart
  }
}
