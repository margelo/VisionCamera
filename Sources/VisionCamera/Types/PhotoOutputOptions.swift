// Copyright © 2025 Marc Rousavy @ Margelo

public struct PhotoOutputOptions: Equatable, Sendable {
  public var targetResolution: Size
  public var containerFormat: TargetPhotoContainerFormat
  public var quality: Double
  public var qualityPrioritization: QualityPrioritization
  public var previewImageTargetSize: Size?

  public init(
    targetResolution: Size = Size(width: 3024, height: 4032),
    containerFormat: TargetPhotoContainerFormat = .native,
    quality: Double = 0.9,
    qualityPrioritization: QualityPrioritization = .balanced,
    previewImageTargetSize: Size? = nil
  ) {
    self.targetResolution = targetResolution
    self.containerFormat = containerFormat
    self.quality = quality
    self.qualityPrioritization = qualityPrioritization
    self.previewImageTargetSize = previewImageTargetSize
  }
}
