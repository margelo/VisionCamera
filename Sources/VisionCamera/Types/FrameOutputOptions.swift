// Copyright © 2025 Marc Rousavy @ Margelo

public struct FrameOutputOptions: Equatable, Sendable {
  public var targetResolution: Size
  public var enablePreviewSizedOutputBuffers: Bool
  public var allowDeferredStart: Bool
  public var pixelFormat: TargetVideoPixelFormat
  public var enablePhysicalBufferRotation: Bool
  public var enableCameraMatrixDelivery: Bool
  public var dropFramesWhileBusy: Bool

  public init(
    targetResolution: Size = Size(width: 720, height: 1280),
    enablePreviewSizedOutputBuffers: Bool = false,
    allowDeferredStart: Bool = true,
    pixelFormat: TargetVideoPixelFormat = .native,
    enablePhysicalBufferRotation: Bool = false,
    enableCameraMatrixDelivery: Bool = false,
    dropFramesWhileBusy: Bool = true
  ) {
    self.targetResolution = targetResolution
    self.enablePreviewSizedOutputBuffers = enablePreviewSizedOutputBuffers
    self.allowDeferredStart = allowDeferredStart
    self.pixelFormat = pixelFormat
    self.enablePhysicalBufferRotation = enablePhysicalBufferRotation
    self.enableCameraMatrixDelivery = enableCameraMatrixDelivery
    self.dropFramesWhileBusy = dropFramesWhileBusy
  }
}
