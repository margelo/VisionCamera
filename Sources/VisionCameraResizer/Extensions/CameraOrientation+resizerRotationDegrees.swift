// Copyright © 2025 Marc Rousavy @ Margelo
// Adapted from Marc Rousavy's implementation, created 10.03.26.

import VisionCamera

extension CameraOrientation {
  var resizerRotationDegrees: Int32 {
    switch self {
    case .up: return 0
    case .right: return 90
    case .down: return 180
    case .left: return 270
    }
  }
}
