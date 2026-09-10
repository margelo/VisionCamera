// Copyright © 2025 Marc Rousavy @ Margelo

/// A video or depth sample delivered by ``OutputSynchronizer``.
///
/// Samples in the same callback are synchronized by the capture pipeline.
public enum SynchronizedFrame {
  /// A video frame in the synchronized sample collection.
  case frame(Frame)
  /// A depth frame in the synchronized sample collection.
  case depth(Depth)
}
