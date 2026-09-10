// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation
import Foundation

protocol ResolvableConstraint {
  associatedtype ResolvedValue
  func resolve(for format: AVCaptureDevice.Format) throws(CameraError) -> ConstraintResolution<ResolvedValue>
}
