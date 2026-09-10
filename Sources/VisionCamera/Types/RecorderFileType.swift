// Copyright © 2025 Marc Rousavy @ Margelo

/// Container file type for ``VideoFrameOutput`` recordings.
///
/// ``MovieFileVideoOutput`` always records QuickTime movies.
public enum RecorderFileType: CaseIterable, Sendable {
  /// The MPEG-4 movie container.
  case mp4
  /// The QuickTime movie container.
  case mov

}
