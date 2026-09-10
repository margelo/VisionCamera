// Copyright © 2025 Marc Rousavy @ Margelo

/// Describes why a ``Recorder``'s recording finished, and was delivered
/// to the `onRecordingFinished` callback passed to
/// ``Recorder/startRecording(onRecordingFinished:onRecordingError:onRecordingPaused:onRecordingResumed:)``.
///
/// In all cases, the resulting video file is fully written and usable - this type
/// only communicates _why_ the recording ended, so the caller can react
/// accordingly (e.g. show a "max length reached" toast, or chain a follow-up
/// recording).
///
/// - ``RecordingFinishedReason/stopped``: The recording was stopped via a
///   ``Recorder/stopRecording()`` call.
/// - ``RecordingFinishedReason/maxDurationReached``: The recording automatically stopped because it
///   reached the configured ``RecorderSettings/maxDuration`` limit.
/// - ``RecordingFinishedReason/maxFileSizeReached``: The recording automatically stopped because it
///   reached the configured ``RecorderSettings/maxFileSize`` limit.
public enum RecordingFinishedReason: CaseIterable, Sendable {
  /// The recording was stopped via a ``Recorder/stopRecording()`` call.
  case stopped
  /// The recording automatically stopped because it reached the configured ``RecorderSettings/maxDuration``
  /// limit.
  case maxDurationReached
  /// The recording automatically stopped because it reached the configured ``RecorderSettings/maxFileSize``
  /// limit.
  case maxFileSizeReached

}
