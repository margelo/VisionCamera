// Copyright © 2025 Marc Rousavy @ Margelo

public enum TargetStabilizationMode: String, CaseIterable, Sendable {
  case off
  case auto
  case standard
  case cinematic
  case cinematicExtended = "cinematic-extended"
  case previewOptimized = "preview-optimized"
  case cinematicExtendedEnhanced = "cinematic-extended-enhanced"
  case lowLatency = "low-latency"

  public var stringValue: String {
    rawValue
  }

  public init?(fromString string: String) {
    self.init(rawValue: string)
  }
}
