///
/// OutputConfiguration.swift
/// VisionCamera
/// Copyright © 2025 Marc Rousavy @ Margelo
///

import AVFoundation
import Foundation

/// Settings applied to an output during a Camera Session configuration batch.
public struct OutputConfiguration {
  /// The target mirroring setting for the output.
  public let mirrorMode: MirrorMode

  /// Creates output settings with the given mirror mode. The default is ``MirrorMode/auto``.
  public init(mirrorMode: MirrorMode = .auto) {
    self.mirrorMode = mirrorMode
  }
}
