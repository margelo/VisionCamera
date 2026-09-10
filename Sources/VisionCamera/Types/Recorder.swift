// Copyright © 2025 Marc Rousavy @ Margelo

import CoreMedia
import Foundation

/// Represents an instance that can record videos to
/// a file.
///
/// A single ``Recorder`` instance records to a single
/// video file.
/// To record multiple videos, you will need to create
/// multiple ``Recorder`` instances.
public protocol Recorder: AnyObject {
  /// Reads the recording state, duration, and file size on the recorder's owning queue.
  ///
  /// A file that has not been created yet reports a size of `0`. Other file-system errors propagate to the caller.
  /// - Returns: The current recording status.
  /// - Throws: An underlying file-system error if the current file size cannot be read.
  func status() async throws -> RecordingStatus
  /// The file URL this Recorder is recording, or will record, to.
  var fileURL: URL { get }

  /// Starts recording to the file selected when this Recorder was created.
  ///
  /// Returns when recording has successfully started. The finished callback runs after the video file has
  /// been finalized.
  ///
  /// - Parameters:
  ///   - onFinished: Called with the finalized video file and the reason recording finished, after a stop request or a configured duration or file-size limit.
  ///   - onError: Called when an unexpected error occurs after recording has started.
  ///   - onPaused: Called when recording pauses.
  ///   - onResumed: Called when a paused recording resumes.
  /// - Throws: An error if recording cannot start. Errors reported before recording starts are thrown to the caller.
  func start(
    onFinished: @escaping (_ result: RecordingResult) -> Void,
    onError: @escaping (_ error: Error) -> Void,
    onPaused: (() -> Void)?,
    onResumed: (() -> Void)?
  ) async throws
  /// Requests the Video recording to stop.
  ///
  /// Returns after the stop request is submitted. Once the file has been finalized, the
  /// `onFinished` callback passed to
  /// ``Recorder/start(onFinished:onError:onPaused:onResumed:)``
  /// is called.
  ///
  /// This operation still submits the stop request when the calling task is cancelled.
  func stop() async
  /// Requests the Video recording to be paused.
  /// Once the recording has actually been paused,
  /// the `onPaused` callback passed to
  /// ``Recorder/start(onFinished:onError:onPaused:onResumed:)``
  /// will be called.
  ///
  /// - Throws: An error if the recording backend does not support this operation. Movie-file recording requires iOS 18 or later; frame-based recording supports this on earlier deployment targets.
  func pause() async throws
  /// Requests the currently paused Video recording
  /// to be resumed.
  /// Once the recording has actually been resumed,
  /// the `onResumed` callback passed to
  /// ``Recorder/start(onFinished:onError:onPaused:onResumed:)``
  /// will be called.
  ///
  /// - Throws: An error if the recording backend does not support this operation. Movie-file recording requires iOS 18 or later; frame-based recording supports this on earlier deployment targets.
  func resume() async throws
  /// Cancels the current recording and deletes
  /// the video file.
  ///
  /// Completion and error callbacks are suppressed for the cancelled recording.
  /// ``FrameRecorder`` removes the file before returning and propagates deletion errors.
  /// ``VideoRecorder`` requests a stop, then attempts to remove the file after AVFoundation finishes;
  /// deletion errors are suppressed.
  ///
  /// - Throws: An error if there is no active recording, or if ``FrameRecorder`` cannot delete the file.
  func cancel() async throws
}
