// Copyright © 2025 Marc Rousavy @ Margelo

/// Represents an instance that can record videos to
/// a file.
///
/// A single ``Recorder`` instance records to a single
/// video file.
/// To record multiple videos, you will need to create
/// multiple ``Recorder`` instances.
public protocol Recorder: AnyObject {
  /// Returns whether the output is currently recording.
  var isRecording: Bool { get }
  /// Returns whether the current recording is paused.
  var isPaused: Bool { get }
  /// The currently recorded duration, in seconds.
  var recordedDuration: Double { get }
  /// The currently recorded file size, in bytes.
  ///
  /// Encoder buffering can cause the on-disk size to lag behind captured data.
  var recordedFileSize: Double { get }
  /// The absolute filesystem path to the file that this Recorder is recording, or will record, to.
  ///
  /// For example, `/var/mobile/.../video.mov`. This is a filesystem path, not a `file://` URL.
  var filePath: String { get }

  /// Starts recording to the path selected when this Recorder was created.
  ///
  /// Returns when recording has successfully started. The finished callback runs after the video file has
  /// been finalized.
  ///
  /// - Parameters:
  ///   - onRecordingFinished: Called with the absolute file path and the reason recording finished, after a stop request or a configured duration or file-size limit.
  ///   - onRecordingError: Called when an unexpected error occurs after recording has started.
  ///   - onRecordingPaused: Called when recording pauses.
  ///   - onRecordingResumed: Called when a paused recording resumes.
  /// - Throws: An error if recording cannot start. Errors reported before recording starts are thrown to the caller.
  func startRecording(
    onRecordingFinished: @escaping (_ filePath: String, _ reason: RecordingFinishedReason) -> Void,
    onRecordingError: @escaping (_ error: Error) -> Void,
    onRecordingPaused: (() -> Void)?,
    onRecordingResumed: (() -> Void)?
  ) async throws
  /// Requests the Video recording to stop.
  ///
  /// Returns after the stop request is submitted. Once the file has been finalized, the
  /// `onRecordingFinished` callback passed to
  /// ``Recorder/startRecording(onRecordingFinished:onRecordingError:onRecordingPaused:onRecordingResumed:)``
  /// is called.
  ///
  /// This operation still submits the stop request when the calling task is cancelled.
  func stopRecording() async
  /// Requests the Video recording to be paused.
  /// Once the recording has actually been paused,
  /// the `onRecordingPaused` callback passed to
  /// ``Recorder/startRecording(onRecordingFinished:onRecordingError:onRecordingPaused:onRecordingResumed:)``
  /// will be called.
  ///
  /// - Throws: An error if the recording backend does not support this operation. Movie-file recording requires iOS 18 or later; frame-based recording supports this on earlier deployment targets.
  func pauseRecording() async throws
  /// Requests the currently paused Video recording
  /// to be resumed.
  /// Once the recording has actually been resumed,
  /// the `onRecordingResumed` callback passed to
  /// ``Recorder/startRecording(onRecordingFinished:onRecordingError:onRecordingPaused:onRecordingResumed:)``
  /// will be called.
  ///
  /// - Throws: An error if the recording backend does not support this operation. Movie-file recording requires iOS 18 or later; frame-based recording supports this on earlier deployment targets.
  func resumeRecording() async throws
  /// Cancels the current recording and deletes
  /// the video file.
  ///
  /// Completion and error callbacks are suppressed for the cancelled recording.
  /// ``FrameRecorder`` removes the file before returning and propagates deletion errors.
  /// ``VideoRecorder`` requests a stop, then attempts to remove the file after AVFoundation finishes;
  /// deletion errors are suppressed.
  ///
  /// - Throws: An error if there is no active recording, or if ``FrameRecorder`` cannot delete the file.
  func cancelRecording() async throws
}
