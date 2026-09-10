// Copyright © 2025 Marc Rousavy @ Margelo

public enum TargetPhotoContainerFormat: String, CaseIterable, Sendable {
  case jpeg
  case heic
  case dng
  case native

  public var stringValue: String {
    rawValue
  }

  public init?(fromString string: String) {
    self.init(rawValue: string)
  }
}
