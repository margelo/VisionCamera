///
/// ResolvedConstraints.swift
/// VisionCamera
/// Copyright © 2025 Marc Rousavy @ Margelo
///

import AVFoundation
import Foundation

struct ResolvedConstraints {
  let device: AVCaptureDevice
  let negotiatedFormat: NegotiatedFormat
  let enabledConstraints: EnabledConstraints
}
