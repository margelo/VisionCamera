// Copyright © 2025 Marc Rousavy @ Margelo

public struct PixelFormatConstraint: Equatable, Sendable {
  public var pixelFormat: PixelFormat

  public init(
    pixelFormat: PixelFormat
  ) {
    self.pixelFormat = pixelFormat
  }
}
