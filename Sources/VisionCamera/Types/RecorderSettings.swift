// Copyright © 2025 Marc Rousavy @ Margelo

import CoreLocation

public struct RecorderSettings {
  public var location: CLLocation?
  public var filePath: String?
  public var maxDuration: Double?
  public var maxFileSize: Double?

  public init(
    location: CLLocation? = nil,
    filePath: String? = nil,
    maxDuration: Double? = nil,
    maxFileSize: Double? = nil
  ) {
    self.location = location
    self.filePath = filePath
    self.maxDuration = maxDuration
    self.maxFileSize = maxFileSize
  }
}
