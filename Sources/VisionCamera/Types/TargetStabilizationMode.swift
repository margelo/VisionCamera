// Copyright © 2025 Marc Rousavy @ Margelo

/// Specifies the stabilization algorithm/mode to use.
///
/// Stabilization uses software and/or hardware processing to reduce visible shake.
/// Most software algorithms reduce the visible field of view (FoV) to account for rapid movements.
/// Some modes may introduce additional latency by buffering frames for stronger stabilization.
/// - ``TargetStabilizationMode/standard``: Enables general-purpose stabilization, typically best for recorded video.
/// - ``TargetStabilizationMode/cinematic``: Uses stronger cinematic-style smoothing.
/// - ``TargetStabilizationMode/cinematicExtended``: Uses an even stronger cinematic-style stabilization mode.
/// - ``TargetStabilizationMode/previewOptimized``: Prioritizes stabilization for the live preview experience.
/// - ``TargetStabilizationMode/cinematicExtendedEnhanced``: Uses the strongest cinematic-style stabilization mode.
/// - ``TargetStabilizationMode/lowLatency``: Prioritizes lower stabilization processing latency.
public enum TargetStabilizationMode: CaseIterable, Sendable {
  /// Disables stabilization entirely.
  case off
  /// Automatically chooses a suitable stabilization mode.
  case auto
  /// Enables general-purpose stabilization, typically best for recorded video.
  case standard
  /// Uses stronger cinematic-style smoothing.
  case cinematic
  /// Uses an even stronger cinematic-style stabilization mode.
  case cinematicExtended
  /// Prioritizes stabilization for the live preview experience.
  case previewOptimized
  /// Uses the strongest cinematic-style stabilization mode.
  case cinematicExtendedEnhanced
  /// Prioritizes lower stabilization processing latency.
  case lowLatency

}
