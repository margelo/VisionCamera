//
//  FrameRecorder.swift
//  VisionCamera
//
//  Created by Marc Rousavy on 05.01.26.
//

import AVFoundation
import Foundation

/// Records Camera frames with `AVAssetWriter`, supporting recordings that continue across Camera switching.
///
/// A single recorder instance records to a single video file. To record multiple videos, create multiple recorder instances through ``VideoOutput/makeRecorder(settings:)``.
public final class FrameRecorder: Recorder {
  private let orientation: CameraOrientation
  private let masterClock: CMClock
  private let fileURL: URL
  private let assetWriter: AVAssetWriter
  private var videoTrack: Track?
  private var audioTrack: Track?
  private let queue: DispatchQueue
  private var isFinishing = false
  private let delegate: RecorderDelegate
  private let settings: RecorderSettings

  /// Sum of all appended sample sizes. Accumulated rather than stat'd because
  /// `AVAssetWriter` buffers writes, so on-disk size lags significantly behind
  /// the actual recorded data until `finishWriting` flushes.
  private var accumulatedBytes: Int64 = 0

  private var onRecordingFinished: ((String, RecordingFinishedReason) -> Void)? = nil
  private var onRecordingError: ((any Error) -> Void)? = nil
  private var onRecordingPaused: (() -> Void)? = nil
  private var onRecordingResumed: (() -> Void)? = nil

  private var isFinished: Bool {
    let isVideoTrackFinished = videoTrack?.isFinished ?? true
    let isAudioTrackFinished = audioTrack?.isFinished ?? true
    return isVideoTrackFinished && isAudioTrackFinished
  }

  init(
    orientation: CameraOrientation,
    masterClock: CMClock,
    fileType: RecorderFileType,
    settings: RecorderSettings,
    delegate: RecorderDelegate
  ) throws {
    self.orientation = orientation
    self.masterClock = masterClock
    if let path = settings.filePath {
      self.fileURL = URL(fileURLWithPath: path)
    } else {
      self.fileURL = try URL.createTempURL(fileType: fileType.toUTType())
    }
    try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
    self.assetWriter = try AVAssetWriter(outputURL: fileURL, fileType: fileType.toAVFileType())
    self.assetWriter.shouldOptimizeForNetworkUse = false
    self.queue = DispatchQueue(
      label: "com.margelo.camera.recorder",
      qos: .utility
    )
    self.delegate = delegate
    self.settings = settings

  }

  deinit {
    if assetWriter.status == .writing {
      logger.error("FrameRecorder was deallocated while writing, cancelling AssetWriter...")
      assetWriter.cancelWriting()
    }
  }

  /// Returns whether the output is currently recording.
  public var isRecording: Bool {
    return assetWriter.status == .writing
  }

  /// Returns whether the current recording is paused.
  public var isPaused: Bool {
    return videoTrack?.isPaused == true
  }

  /// Returns the currently recorded duration, in seconds.
  public var recordedDuration: Double {
    return videoTrack?.duration.seconds ?? 0.0
  }

  /// Returns the currently recorded file size, in bytes. Buffered writes can make the on-disk size lag behind recording; returns `0` if the file size is unavailable.
  public var recordedFileSize: Double {
    if let attrs = try? FileManager.default.attributesOfItem(atPath: filePath),
      let sizeBytes = attrs[.size] as? NSNumber
    {
      return sizeBytes.doubleValue
    }
    return 0.0
  }

  /// Returns the absolute filesystem path to the file this recorder is recording, or will record, to. This is a path such as `/var/mobile/.../video.mp4`, not a `file://` URL.
  public var filePath: String {
    return fileURL.path
  }

  func initializeVideoTrack(withSettings settings: [String: Any]) throws {
    guard !settings.isEmpty else {
      throw CameraError(message: "Tried to initialize Video Track with empty options!")
    }
    guard videoTrack == nil else {
      throw CameraError(message: "Tried to initialize Video Track twice!")
    }
    guard assetWriter.canApply(outputSettings: settings, forMediaType: .video) else {
      throw CameraError(
        message: "The given output settings are not supported! \(settings)")
    }

    logger.info("Initializing Video AssetWriter with settings: \(settings)")
    let videoWriter = AVAssetWriterInput(mediaType: .video, outputSettings: settings)
    videoWriter.expectsMediaDataInRealTime = true
    videoWriter.transform = orientation.affineTransform
    assetWriter.add(videoWriter)
    videoTrack = Track(ofType: .video, withAssetWriterInput: videoWriter, andClock: masterClock)
    logger.info("Initialized Video AssetWriter!")
  }

  func setTimescale(_ timescale: CMTimeScale) {
    logger.info("Setting AVAssetWriter timescale to \(timescale)...")
    assetWriter.movieTimeScale = timescale
  }

  func setMetadata(_ metadata: [AVMetadataItem], settings: RecorderSettings) throws {
    logger.info("Setting AVAssetWriter metadata: \(metadata)...")
    var metadata = metadata
    metadata.append(.libraryTag)
    if let location = settings.location {
      let locationTag = try location.toAVMutableMetadataItem()
      metadata.append(locationTag)
    }
    assetWriter.metadata = metadata
  }

  func initializeAudioTrack(withSettings settings: [String: Any]?, format: CMFormatDescription)
    throws
  {
    guard audioTrack == nil else {
      throw CameraError(message: "Tried to initialize Audio Track twice!")
    }

    if let settings = settings {
      logger.info("Initializing Audio AssetWriter with settings: \(settings)")
    } else {
      logger.info("Initializing Audio AssetWriter default settings...")
    }
    let audioWriter = AVAssetWriterInput(
      mediaType: .audio, outputSettings: settings, sourceFormatHint: format)
    audioWriter.expectsMediaDataInRealTime = true
    assetWriter.add(audioWriter)
    audioTrack = Track(ofType: .audio, withAssetWriterInput: audioWriter, andClock: masterClock)
    logger.info("Initialized Audio AssetWriter!")
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
  /// - Throws: If this recorder has already been started or recording fails to start.
  public func startRecording(
    onRecordingFinished: @escaping (String, RecordingFinishedReason) -> Void,
    onRecordingError: @escaping (any Error) -> Void,
    onRecordingPaused: (() -> Void)? = nil,
    onRecordingResumed: (() -> Void)? = nil
  ) async throws {
    return try await queue.perform {
      guard self.assetWriter.status == .unknown, !self.isFinishing else {
        throw CameraError(message: "A recorder can only be started once.")
      }

      // Notify about to start
      self.delegate.onRecorderWillStart()

      // Prepare the AssetWriter for writing to the video file
      let success = self.assetWriter.startWriting()
      guard success else {
        self.delegate.onRecorderDidStop()
        throw self.assetWriter.error ?? CameraError(message: "Failed to start AssetWriter.")
      }
      logger.info("AssetWriter started writing to \(self.filePath)!")

      // Assign callbacks
      self.onRecordingFinished = onRecordingFinished
      self.onRecordingError = onRecordingError
      self.onRecordingPaused = onRecordingPaused
      self.onRecordingResumed = onRecordingResumed

      // Start the session at the specific timestamp
      let now = self.masterClock.time
      self.assetWriter.startSession(atSourceTime: now)

      // Start each track
      self.videoTrack?.start()
      self.audioTrack?.start()
    }
  }

  /// Requests the Video recording to be stopped.
  ///
  /// Once the recording has actually stopped and the file is written, the `onRecordingFinished` callback passed to `startRecording` is called. Returning from this method does not mean the file is finalized.
  public func stopRecording() async {
    return await queue.perform {
      // Stop each track
      self.videoTrack?.stop()
      self.audioTrack?.stop()

      // Start a timeout that will force-stop the session if it still hasn't been stopped (maybe no more frames came in?)
      let videoLatency = self.videoTrack?.latency.seconds ?? 0.0
      let audioLatency = self.audioTrack?.latency.seconds ?? 0.0
      let latency = max(videoLatency, audioLatency)
      let timeout = max(latency * 2, 0.1)
      self.queue.asyncAfter(
        deadline: .now() + timeout,
        execute: DispatchWorkItem {
          if !self.isFinishing {
            logger.error(
              "Waited \(timeout) seconds, but the session is still not finished - force-stopping session..."
            )
            self.finish(reason: .stopped)
          }
        })
    }
  }

  /// Requests the Video recording to be paused.
  /// Once the recording has actually been paused,
  /// the `onRecordingPaused` callback passed to
  /// ``FrameRecorder/startRecording(onRecordingFinished:onRecordingError:onRecordingPaused:onRecordingResumed:)`` will be called.
  public func pauseRecording() async {
    return await queue.perform {
      // Pause each track
      self.videoTrack?.pause()
      self.audioTrack?.pause()

      // Notify listener
      self.onRecordingPaused?()
    }
  }

  /// Requests the currently paused Video recording
  /// to be resumed.
  /// Once the recording has actually been resumed,
  /// the `onRecordingResumed` callback passed to
  /// ``FrameRecorder/startRecording(onRecordingFinished:onRecordingError:onRecordingPaused:onRecordingResumed:)`` will be called.
  public func resumeRecording() async {
    return await queue.perform {
      // Resume each track
      self.videoTrack?.resume()
      self.audioTrack?.resume()

      // Notify listener
      self.onRecordingResumed?()
    }
  }

  /// Cancels the current recording and deletes
  /// the video file.
  ///
  /// Cancels writing on the recorder queue and removes the file. Completion callbacks are suppressed; file removal errors propagate to the caller. Throws if no recording is active.
  public func cancelRecording() async throws {
    return try await queue.perform {
      guard self.assetWriter.status == .writing else {
        throw CameraError(message: "Not currently recording!")
      }
      // Clear callbacks so they don't fire during cancellation
      self.onRecordingFinished = nil
      self.onRecordingError = nil
      self.onRecordingPaused = nil
      self.onRecordingResumed = nil
      // Cancel the writing session
      self.isFinishing = true
      self.assetWriter.cancelWriting()
      self.delegate.onRecorderDidStop()
      // Delete the temporary file
      try FileManager.default.removeItem(at: self.fileURL)
    }
  }

  func append(buffer: CMSampleBuffer, ofType type: TrackType) {
    queue.async(
      execute: DispatchWorkItem {
        guard !self.isFinishing else {
          // Session is already finishing, can't write anything more
          return
        }
        guard self.assetWriter.status == .writing else { return }

        // Write buffer to video/audio track
        do {
          let track = try self.getTrack(ofType: type)
          try track.append(buffer: buffer)
          self.accumulatedBytes += Int64(CMSampleBufferGetTotalSampleSize(buffer))
        } catch {
          logger.error("Failed to append buffer to \(type.rawValue) track! \(error)")
          self.fail(self.assetWriter.error ?? error)
          return
        }

        // If we failed to write the frames, stop the Recording
        if self.assetWriter.status == .failed {
          logger.error("Failed to write buffer: \(self.assetWriter.error)")
          let error = self.assetWriter.error ?? CameraError(message: "Failed to write Buffer!")
          self.fail(self.assetWriter.error ?? error)
          return
        }

        // Check if we reached limits (file size or duration), if yes; stop
        if self.reachedDurationLimit() {
          self.finish(reason: .maxDurationReached)
          return
        }
        if self.reachedFileSizeLimit() {
          self.finish(reason: .maxFileSizeReached)
          return
        }

        // When all tracks (video + audio) are finished (via `stopRecording`),
        // finish the Recording.
        if self.isFinished {
          self.finish(reason: .stopped)
        }
      })
  }

  private func reachedFileSizeLimit() -> Bool {
    if let maxFileSize = settings.maxFileSize {
      // Check if video size >= max target file size
      if accumulatedBytes >= Int64(maxFileSize) {
        logger.info("Reached maxFileSize of \(maxFileSize) bytes - finishing recording.")
        return true
      }
    }
    return false
  }
  private func reachedDurationLimit() -> Bool {
    if let maxDuration = settings.maxDuration,
      let duration = videoTrack?.duration
    {
      // Check if video track duration >= max target duration
      let maxDuration = CMTime(seconds: maxDuration, preferredTimescale: 600)
      if CMTimeCompare(duration, maxDuration) >= 0 {
        logger.info("Reached maxDuration of \(maxDuration.seconds)s - finishing recording.")
        return true
      }
    }
    return false
  }

  @inline(__always)
  private func getTrack(ofType type: TrackType) throws -> Track {
    switch type {
    case .audio:
      guard let audioTrack else {
        throw CameraError(
          message: "Tried to write an audio buffer, but no audio track was initialized!")
      }
      return audioTrack
    case .video:
      guard let videoTrack else {
        throw CameraError(
          message: "Tried to write a video buffer, but no video track was initialized!")
      }
      return videoTrack
    }
  }

  private func finish(reason: RecordingFinishedReason) {
    guard !isFinishing else { return }
    guard let lastVideoTimestamp = videoTrack?.lastTimestamp else {
      fail(CameraError(message: "Cannot finish a recording before its first video frame."))
      return
    }
    guard assetWriter.status == .writing else {
      fail(assetWriter.error ?? CameraError(message: "AssetWriter is not writing."))
      return
    }
    isFinishing = true
    assetWriter.endSession(atSourceTime: lastVideoTimestamp)
    assetWriter.finishWriting {
      self.queue.async(
        execute: DispatchWorkItem {
          if self.assetWriter.status == .completed {
            self.onRecordingFinished?(self.filePath, reason)
          } else {
            self.onRecordingError?(self.assetWriter.error ?? CameraError(message: "Failed to finalize the recording."))
          }
          self.clearCallbacks()
          self.delegate.onRecorderDidStop()
        })
    }
  }

  private func fail(_ error: Error) {
    guard !isFinishing else { return }
    isFinishing = true
    if assetWriter.status == .writing { assetWriter.cancelWriting() }
    onRecordingError?(error)
    clearCallbacks()
    delegate.onRecorderDidStop()
  }

  private func clearCallbacks() {
    onRecordingFinished = nil
    onRecordingError = nil
    onRecordingPaused = nil
    onRecordingResumed = nil
  }
}
