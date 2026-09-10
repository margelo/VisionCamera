///
/// VideoRecorder.swift
/// VisionCamera
/// Copyright © 2025 Marc Rousavy @ Margelo
///

import AVFoundation
import Foundation

/// Records video using `AVCaptureMovieFileOutput`.
///
/// A single recorder instance records to a single video file. To record multiple videos, create multiple recorder instances through ``VideoOutput/makeRecorder(settings:)``.
public final class VideoRecorder: Recorder {
  private let videoOutput: AVCaptureMovieFileOutput
  private let queue: DispatchQueue
  private let coordinator: MovieFileRecordingCoordinator
  private let recordingID = UUID()
  /// The file URL this recorder is recording, or will record, to.
  public let fileURL: URL
  private let settings: RecorderSettings
  private let locationMetadata: AVMetadataItem?
  private var isCancelled = false
  private var hasStarted = false
  private var activeDelegate: VideoDelegate?
  private var terminalStatus = RecordingStatus(isRecording: false, isPaused: false, duration: .invalid, fileSize: 0)

  init(
    videoOutput: AVCaptureMovieFileOutput,
    queue: DispatchQueue,
    coordinator: MovieFileRecordingCoordinator,
    fileType: RecorderFileType,
    settings: RecorderSettings
  ) throws {
    self.videoOutput = videoOutput
    self.queue = queue
    self.coordinator = coordinator
    try settings.validate()
    self.locationMetadata = try settings.location?.toAVMutableMetadataItem()
    if let fileURL = settings.fileURL {
      self.fileURL = fileURL
    } else {
      self.fileURL = try URL.createTempURL(fileType: fileType.toUTType())
    }
    // Create all parent directories if they don't exist yet.
    try FileManager.default.createDirectory(
      at: self.fileURL.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )
    self.settings = settings
  }

  /// Reads this recorder's state and native file progress on the output's owning queue.
  ///
  /// Before this recorder starts, duration is invalid and file size is zero. After recording finishes,
  /// this returns its final progress even when another recorder uses the same output.
  /// - Returns: The current recording status.
  public func status() async -> RecordingStatus {
    return await queue.perform {
      guard self.activeDelegate != nil else { return self.terminalStatus }
      return self.currentStatus()
    }
  }

  private func currentStatus() -> RecordingStatus {
    let isPaused: Bool
    if #available(iOS 18.0, *) {
      isPaused = videoOutput.isRecordingPaused
    } else {
      isPaused = false
    }
    return RecordingStatus(
      isRecording: videoOutput.isRecording,
      isPaused: isPaused,
      duration: videoOutput.recordedDuration,
      fileSize: videoOutput.recordedFileSize)
  }

  private func recordingDidFinish() {
    let status = currentStatus()
    terminalStatus = RecordingStatus(
      isRecording: false, isPaused: false, duration: status.duration, fileSize: status.fileSize)
    activeDelegate = nil
    coordinator.release(for: recordingID)
  }

  /// Starts recording to the file selected when this recorder was created.
  ///
  /// Returns once recording has successfully started. Read ``fileURL`` for the destination, or use the ``RecordingResult`` delivered to `onFinished` after finalization.
  /// The recording continues after this method returns. Completion or failure is reported through the callbacks.
  /// Callbacks run on the recorder's owning serial queue. Move UIKit work to the main actor.
  ///
  /// - Parameter onFinished: Called when recording finishes and the file has been written, including when a configured duration or file-size limit is reached.
  /// - Parameter onError: Called when an unexpected error occurs while recording.
  /// - Parameter onPaused: Called when recording pauses.
  /// - Parameter onResumed: Called when recording resumes.
  /// - Throws: If the output is disconnected, a recording is already active, or recording fails to start.
  public func start(
    onFinished: @escaping (_ result: RecordingResult) -> Void,
    onError: @escaping (_ error: Error) -> Void,
    onPaused: (() -> Void)? = nil,
    onResumed: (() -> Void)? = nil
  ) async throws {
    try Task.checkCancellation()
    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
      queue.async(
        execute: DispatchWorkItem {
          guard self.videoOutput.connection(with: .video) != nil else {
            continuation.resume(throwing: RecordingError.outputNotConnected)
            return
          }
          guard !self.hasStarted else {
            continuation.resume(throwing: RecordingError.alreadyStarted)
            return
          }
          guard self.activeDelegate == nil, !self.videoOutput.isRecording else {
            continuation.resume(throwing: RecordingError.recordingInProgress)
            return
          }
          do {
            try self.coordinator.reserve(for: self.recordingID)
          } catch {
            continuation.resume(throwing: error)
            return
          }
          self.videoOutput.applyLocationMetadata(self.locationMetadata)
          var didStart = false
          self.hasStarted = true
          self.isCancelled = false
          let delegate = VideoDelegate(
            queue: self.queue,
            onRecordingStarted: {
              didStart = true
              continuation.resume()
            },
            onRecordingPaused: onPaused,
            onRecordingResumed: onResumed,
            onRecordingFinished: { url, reason in
              self.recordingDidFinish()
              if self.isCancelled { try? FileManager.default.removeItem(at: url) }
              guard didStart else {
                continuation.resume(throwing: RecordingError.finishedBeforeStarting)
                return
              }
              if !self.isCancelled {
                onFinished(RecordingResult(fileURL: url, reason: reason))
              }
            },
            onRecordingError: { error in
              self.recordingDidFinish()
              if !didStart {
                continuation.resume(throwing: error)
              } else if !self.isCancelled {
                onError(error)
              }
              if self.isCancelled { try? FileManager.default.removeItem(at: self.fileURL) }
            })
          self.activeDelegate = delegate
          if let duration = self.settings.maxDuration {
            self.videoOutput.maxRecordedDuration = duration
          } else {
            self.videoOutput.maxRecordedDuration = .invalid
          }
          self.videoOutput.maxRecordedFileSize = self.settings.maxFileSize ?? 0
          self.videoOutput.startRecording(to: self.fileURL, recordingDelegate: delegate)
        })
    }
  }

  /// Requests the Video recording to be stopped.
  ///
  /// Once the recording has actually stopped and the file is written, the `onFinished` callback passed to `start` is called. Returning from this method does not mean the file is finalized. Stopping a recording that is already stopped has no effect.
  public func stop() async {
    return await queue.perform {
      guard self.activeDelegate != nil else { return }
      self.videoOutput.stopRecording()
    }
  }

  /// Requests the Video recording to be paused.
  /// Once the recording has actually been paused,
  /// the `onPaused` callback passed to
  /// ``VideoRecorder/start(onFinished:onError:onPaused:onResumed:)`` will be called.
  ///
  /// - Throws: If this recorder has no active recording, or on iOS versions earlier than iOS 18.
  public func pause() async throws {
    return try await queue.perform {
      guard self.activeDelegate != nil else { throw RecordingError.notRecording }
      guard #available(iOS 18.0, *) else {
        throw RecordingError.pauseRequiresIOS18
      }
      self.videoOutput.pauseRecording()
    }
  }

  /// Requests the currently paused Video recording
  /// to be resumed.
  /// Once the recording has actually been resumed,
  /// the `onResumed` callback passed to
  /// ``VideoRecorder/start(onFinished:onError:onPaused:onResumed:)`` will be called.
  ///
  /// - Throws: If this recorder has no active recording, or on iOS versions earlier than iOS 18.
  public func resume() async throws {
    return try await queue.perform {
      guard self.activeDelegate != nil else { throw RecordingError.notRecording }
      guard #available(iOS 18.0, *) else {
        throw RecordingError.resumeRequiresIOS18
      }
      self.videoOutput.resumeRecording()
    }
  }

  /// Cancels the current recording and deletes
  /// the video file.
  ///
  /// Requests stopping, then deletes the file when AVFoundation finishes. Completion and error callbacks are suppressed for cancellation. Throws if no recording is active.
  public func cancel() async throws {
    return try await queue.perform {
      guard self.activeDelegate != nil, self.videoOutput.isRecording else {
        throw RecordingError.notRecording
      }
      // Mark as cancelled so the onFinished callback
      // deletes the file instead of notifying the caller
      self.isCancelled = true
      self.videoOutput.stopRecording()
    }
  }
}
