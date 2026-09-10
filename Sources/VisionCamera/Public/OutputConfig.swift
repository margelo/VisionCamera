///
/// OutputConfiguration.swift
/// VisionCamera
/// Copyright © 2025 Marc Rousavy @ Margelo
///

import AVFoundation
import Foundation

public struct OutputConfiguration {
  public let mirrorMode: MirrorMode

  public init(mirrorMode: MirrorMode = .auto) {
    self.mirrorMode = mirrorMode
  }
}
