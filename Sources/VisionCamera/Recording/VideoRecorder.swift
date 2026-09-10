///
/// VideoRecorder.swift
/// VisionCamera
/// Copyright © 2025 Marc Rousavy @ Margelo
///

import AVFoundation
import Foundation

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

  public var isRecording: Bool {
    return videoOutput.isRecording
  }
  public var isPaused: Bool {
    guard #available(iOS 18.0, *) else {
      return false
    }
    return videoOutput.isRecordingPaused
  }
  public var recordedDuration: Double {
    return videoOutput.recordedDuration.seconds
  }
  public var recordedFileSize: Double {
    return Double(videoOutput.recordedFileSize)
  }
  public var filePath: String {
    return fileURL.path
  }

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
          self.videoOutput.maxRecordedFileSize = self.settings.maxFileSize.map(Int64.init) ?? 0
          self.videoOutput.startRecording(to: self.fileURL, recordingDelegate: delegate)
        })
    }
  }

  public func stopRecording() async throws {
    return try await queue.perform {
      self.videoOutput.stopRecording()
    }
  }

  public func pauseRecording() async throws {
    return try await queue.perform {
      guard #available(iOS 18.0, *) else {
        throw CameraError(
          message: "`pauseRecording()` is only available on iOS 18 or above!")
      }
      self.videoOutput.pauseRecording()
    }
  }

  public func resumeRecording() async throws {
    return try await queue.perform {
      guard #available(iOS 18.0, *) else {
        throw CameraError(
          message: "`resumeRecording()` is only available on iOS 18 or above!")
      }
      self.videoOutput.resumeRecording()
    }
  }

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
