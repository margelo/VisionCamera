// Copyright © 2025 Marc Rousavy @ Margelo

public enum PhotoContainerFormat: String, CaseIterable, Sendable {
  case unknown
  case jpeg
  case heic
  case dng
  case tiff
  case dcm

  public var stringValue: String {
    rawValue
  }

  public init?(fromString string: String) {
    self.init(rawValue: string)
  }
}
