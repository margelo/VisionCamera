// Copyright © 2025 Marc Rousavy @ Margelo

import Foundation

/// Reserves one native movie-file output until its recording delegate delivers the terminal event.
/// All access belongs to the owning MovieFileVideoOutput queue.
final class MovieFileRecordingCoordinator {
  private var activeRecordingID: UUID?

  func reserve(for recordingID: UUID) throws(RecordingError) {
    guard activeRecordingID == nil else { throw .recordingInProgress }
    activeRecordingID = recordingID
  }

  func release(for recordingID: UUID) {
    guard activeRecordingID == recordingID else { return }
    activeRecordingID = nil
  }
}
