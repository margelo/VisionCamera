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
  private let fileURL: URL
  private let settings: RecorderSettings
  private var isCancelled = false
  private var activeDelegate: VideoDelegate?

  init(
    videoOutput: AVCaptureMovieFileOutput,
    queue: DispatchQueue,
    fileType: RecorderFileType,
    settings: RecorderSettings
  ) throws {
    self.videoOutput = videoOutput
    self.queue = queue
    if let customFilePath = settings.filePath {
      self.fileURL = URL(fileURLWithPath: customFilePath)
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

  /// Returns whether the output is currently recording.
  public var isRecording: Bool {
    return videoOutput.isRecording
  }
  /// Returns whether the current recording is paused.
  public var isPaused: Bool {
    guard #available(iOS 18.0, *) else {
      return false
    }
    return videoOutput.isRecordingPaused
  }
  /// Returns the currently recorded duration, in seconds.
  public var recordedDuration: Double {
    return videoOutput.recordedDuration.seconds
  }
  /// Returns the currently recorded file size, in bytes.
  public var recordedFileSize: Int64 {
    return videoOutput.recordedFileSize
  }
  /// Returns the absolute filesystem path to the file this recorder is recording, or will record, to. This is a path such as `/var/mobile/.../video.mov`, not a `file://` URL.
  public var filePath: String {
    return fileURL.path
  }

  /// Starts recording to the file selected when this recorder was created.
  ///
  /// Returns once recording has successfully started. Read `filePath` for the filesystem path being recorded to, or use the path delivered to `onRecordingFinished` after finalization. Neither path is a `file://` URL.
  /// The recording continues after this method returns. Completion or failure is reported through the callbacks.
  /// Callbacks run on the recorder's owning serial queue. Move UIKit work to the main actor.
  ///
  /// - Parameter onRecordingFinished: Called when recording finishes and the file has been written, including when a configured duration or file-size limit is reached.
  /// - Parameter onRecordingError: Called when an unexpected error occurs while recording.
  /// - Parameter onRecordingPaused: Called when recording pauses.
  /// - Parameter onRecordingResumed: Called when recording resumes.
  /// - Throws: If the output is disconnected, a recording is already active, or recording fails to start.
  public func startRecording(
    onRecordingFinished: @escaping (_ filePath: String, _ reason: RecordingFinishedReason) -> Void,
    onRecordingError: @escaping (_ error: Error) -> Void,
    onRecordingPaused: (() -> Void)? = nil,
    onRecordingResumed: (() -> Void)? = nil
  ) async throws {
    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
      queue.async(
        execute: DispatchWorkItem {
          guard self.videoOutput.connection(with: .video) != nil else {
            continuation.resume(throwing: CameraError(message: "VideoOutput is not yet connected to the CameraSession!"))
            return
          }
          guard self.activeDelegate == nil, !self.videoOutput.isRecording else {
            continuation.resume(throwing: CameraError(message: "Active recording already in progress!"))
            return
          }
          var didStart = false
          self.isCancelled = false
          let delegate = VideoDelegate(
            queue: self.queue,
            onRecordingStarted: {
              didStart = true
              continuation.resume()
            },
            onRecordingPaused: onRecordingPaused,
            onRecordingResumed: onRecordingResumed,
            onRecordingFinished: { url, reason in
              self.activeDelegate = nil
              if !didStart {
                continuation.resume(throwing: CameraError(message: "Recording finished before it started."))
              }
              if self.isCancelled {
                try? FileManager.default.removeItem(at: url)
              } else {
                onRecordingFinished(url.path, reason)
              }
            },
            onRecordingError: { error in
              self.activeDelegate = nil
              if !didStart {
                continuation.resume(throwing: error)
              } else if !self.isCancelled {
                onRecordingError(error)
              }
              if self.isCancelled { try? FileManager.default.removeItem(at: self.fileURL) }
            })
          self.activeDelegate = delegate
          if let duration = self.settings.maxDuration {
            self.videoOutput.maxRecordedDuration = CMTime(seconds: duration, preferredTimescale: 600)
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
  /// Once the recording has actually stopped and the file is written, the `onRecordingFinished` callback passed to `startRecording` is called. Returning from this method does not mean the file is finalized. Stopping a recording that is already stopped has no effect.
  public func stopRecording() async {
    return await queue.perform {
      self.videoOutput.stopRecording()
    }
  }

  /// Requests the Video recording to be paused.
  /// Once the recording has actually been paused,
  /// the `onRecordingPaused` callback passed to
  /// ``VideoRecorder/startRecording(onRecordingFinished:onRecordingError:onRecordingPaused:onRecordingResumed:)`` will be called.
  ///
  /// - Throws: On iOS versions earlier than iOS 18.
  public func pauseRecording() async throws {
    return try await queue.perform {
      guard #available(iOS 18.0, *) else {
        throw CameraError(
          message: "`pauseRecording()` is only available on iOS 18 or above!")
      }
      self.videoOutput.pauseRecording()
    }
  }

  /// Requests the currently paused Video recording
  /// to be resumed.
  /// Once the recording has actually been resumed,
  /// the `onRecordingResumed` callback passed to
  /// ``VideoRecorder/startRecording(onRecordingFinished:onRecordingError:onRecordingPaused:onRecordingResumed:)`` will be called.
  ///
  /// - Throws: On iOS versions earlier than iOS 18.
  public func resumeRecording() async throws {
    return try await queue.perform {
      guard #available(iOS 18.0, *) else {
        throw CameraError(
          message: "`resumeRecording()` is only available on iOS 18 or above!")
      }
      self.videoOutput.resumeRecording()
    }
  }

  /// Cancels the current recording and deletes
  /// the video file.
  ///
  /// Requests stopping, then deletes the file when AVFoundation finishes. Completion and error callbacks are suppressed for cancellation. Throws if no recording is active.
  public func cancelRecording() async throws {
    return try await queue.perform {
      guard self.videoOutput.isRecording else {
        throw CameraError(message: "Not currently recording!")
      }
      // Mark as cancelled so the onRecordingFinished callback
      // deletes the file instead of notifying the caller
      self.isCancelled = true
      self.videoOutput.stopRecording()
    }
  }
}
