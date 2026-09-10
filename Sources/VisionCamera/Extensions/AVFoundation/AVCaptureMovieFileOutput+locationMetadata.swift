// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation
import Foundation

extension AVCaptureMovieFileOutput {
  /// Replaces only the recording's location tag while preserving unrelated metadata.
  /// Call on the output's owning queue after reserving it for a new recording.
  func applyLocationMetadata(_ item: AVMetadataItem?) {
    var metadata = self.metadata ?? []
    metadata.removeAll { existing in
      existing.keySpace == .quickTimeMetadata
        && existing.key as? String == AVMetadataKey.quickTimeMetadataKeyLocationISO6709.rawValue
    }
    if let item { metadata.append(item) }
    self.metadata = metadata
  }
}
