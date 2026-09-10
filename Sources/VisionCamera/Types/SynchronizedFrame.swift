// Copyright © 2025 Marc Rousavy @ Margelo

import CoreMedia

/// A video, depth, metadata, or audio sample delivered by ``OutputSynchronizer``.
///
/// Samples in the same callback are synchronized by the capture pipeline.
public enum SynchronizedFrame {
  /// A video frame in the synchronized sample collection.
  case frame(Frame)
  /// An audio sample buffer from a native audio data output, with its original presentation timestamp.
  case audio(CMSampleBuffer)
  /// A depth frame in the synchronized sample collection.
  case depth(Depth)
  /// Metadata objects at the supplied capture timestamp, including an empty array when none were detected.
  case metadata(objects: [any ScannedObject], timestamp: CMTime)
}
