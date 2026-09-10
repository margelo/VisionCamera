// Copyright © 2025 Marc Rousavy @ Margelo

public struct PhotoFile: Equatable, Sendable {
  public var filePath: String
  public var width: Double
  public var height: Double
  public var orientation: CameraOrientation
  public var isMirrored: Bool
  public var timestamp: Double
  public var isRawPhoto: Bool
  public var containerFormat: PhotoContainerFormat

  public init(
    filePath: String,
    width: Double,
    height: Double,
    orientation: CameraOrientation,
    isMirrored: Bool,
    timestamp: Double,
    isRawPhoto: Bool,
    containerFormat: PhotoContainerFormat
  ) {
    self.filePath = filePath
    self.width = width
    self.height = height
    self.orientation = orientation
    self.isMirrored = isMirrored
    self.timestamp = timestamp
    self.isRawPhoto = isRawPhoto
    self.containerFormat = containerFormat
  }
}
