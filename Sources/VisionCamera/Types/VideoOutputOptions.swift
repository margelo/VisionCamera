// Copyright © 2025 Marc Rousavy @ Margelo

public struct VideoOutputOptions: Equatable, Sendable {
  public var targetResolution: Size
  public var enableAudio: Bool?
  public var enablePersistentRecorder: Bool?
  public var enableHigherResolutionCodecs: Bool?
  public var targetBitRate: Double?
  public var fileType: RecorderFileType?

  public init(
    targetResolution: Size = Size(width: 1080, height: 1920),
    enableAudio: Bool? = nil,
    enablePersistentRecorder: Bool? = nil,
    enableHigherResolutionCodecs: Bool? = nil,
    targetBitRate: Double? = nil,
    fileType: RecorderFileType? = nil
  ) {
    self.targetResolution = targetResolution
    self.enableAudio = enableAudio
    self.enablePersistentRecorder = enablePersistentRecorder
    self.enableHigherResolutionCodecs = enableHigherResolutionCodecs
    self.targetBitRate = targetBitRate
    self.fileType = fileType
  }
}
