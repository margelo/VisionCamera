// Copyright © 2025 Marc Rousavy @ Margelo

public enum PermissionStatus: String, CaseIterable, Sendable {
  case notDetermined = "not-determined"
  case authorized
  case denied
  case restricted

  public var stringValue: String {
    rawValue
  }

  public init?(fromString string: String) {
    self.init(rawValue: string)
  }
}
