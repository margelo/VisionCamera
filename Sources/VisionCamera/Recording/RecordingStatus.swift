// Copyright © 2025 Marc Rousavy @ Margelo

import CoreMedia
import Foundation

/// A snapshot of a recorder's state, captured on its owning queue.
public struct RecordingStatus: Equatable, Sendable {
  /// Whether the recorder is currently recording, including a paused recording.
  public let isRecording: Bool
  /// Whether the active recording is paused.
  public let isPaused: Bool
  /// The duration of the recorded media timeline, excluding pauses.
  public let duration: CMTime
  /// The size of the current output file, in bytes.
  ///
  /// Encoder buffering can cause the file size to lag behind captured data. Before the file exists, this is `0`.
  public let fileSize: Int64

  /// Describes the recorder's state at one point in time.
  /// - Parameters:
  ///   - isRecording: Whether a recording is active.
  ///   - isPaused: Whether the active recording is paused.
  ///   - duration: The duration of recorded media, excluding pauses.
  ///   - fileSize: The output file size, in bytes.
  public init(isRecording: Bool, isPaused: Bool, duration: CMTime, fileSize: Int64) {
    self.isRecording = isRecording
    self.isPaused = isPaused
    self.duration = duration
    self.fileSize = fileSize
  }
}
