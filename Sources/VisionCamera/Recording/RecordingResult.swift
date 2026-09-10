// Copyright © 2025 Marc Rousavy @ Margelo

import Foundation

/// The finalized video file and the reason its recording finished.
public struct RecordingResult: Equatable, Sendable {
  /// The file URL of the completed recording.
  public let fileURL: URL
  /// Whether the recording stopped on request or reached a configured limit.
  public let reason: RecordingFinishedReason

  /// Describes a recording after its output file has been finalized.
  /// - Parameters:
  ///   - fileURL: The file URL of the completed recording.
  ///   - reason: The reason the recording finished.
  public init(fileURL: URL, reason: RecordingFinishedReason) {
    self.fileURL = fileURL
    self.reason = reason
  }
}
