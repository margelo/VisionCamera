// Copyright © 2025 Marc Rousavy @ Margelo

public protocol Recorder: AnyObject {
  var isRecording: Bool { get }
  var isPaused: Bool { get }
  var recordedDuration: Double { get }
  var recordedFileSize: Double { get }
  var filePath: String { get }

  /// Returns when recording has started. The finished callback runs after the file is finalized.
  func startRecording(
    onRecordingFinished: @escaping (_ filePath: String, _ reason: RecordingFinishedReason) -> Void,
    onRecordingError: @escaping (_ error: Error) -> Void,
    onRecordingPaused: (() -> Void)?,
    onRecordingResumed: (() -> Void)?
  ) async throws
  func stopRecording() async throws
  func pauseRecording() async throws
  func resumeRecording() async throws
  func cancelRecording() async throws
}
