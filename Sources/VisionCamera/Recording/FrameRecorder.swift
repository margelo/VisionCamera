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
  /// The file URL this recorder is recording, or will record, to.
  public let fileURL: URL
  private let assetWriter: AVAssetWriter
  private var videoTrack: Track?
  private var audioTrack: Track?
  private let queue: DispatchQueue
  private var isFinishing = false
  private var didNotifyDelegateOfStart = false
  private let delegate: RecorderDelegate
  private let settings: RecorderSettings

  private var onFinished: ((RecordingResult) -> Void)? = nil
  private var onError: ((any Error) -> Void)? = nil
  private var onPaused: (() -> Void)? = nil
  private var onResumed: (() -> Void)? = nil

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
    try settings.validate()
    if let fileURL = settings.fileURL {
      self.fileURL = fileURL
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
    if didNotifyDelegateOfStart { delegate.onRecorderDidStop() }
    if assetWriter.status == .writing {
      logger.error("FrameRecorder was deallocated while writing, cancelling AssetWriter...")
      assetWriter.cancelWriting()
    }
  }

  /// Reads the recording state and output file size on the recorder's owning queue.
  ///
  /// Buffered writes can make the on-disk size lag behind captured data. A file that has not been created yet reports a size of `0`.
  /// - Returns: The current recording status.
  /// - Throws: An underlying file-system error if the file size cannot be read.
  public func status() async throws -> RecordingStatus {
    return try await queue.perform {
      let fileSize: Int64
      do {
        let attributes = try FileManager.default.attributesOfItem(atPath: self.fileURL.path)
        fileSize = (attributes[.size] as? NSNumber)?.int64Value ?? 0
      } catch let error as NSError
        where error.domain == NSCocoaErrorDomain
        && (error.code == NSFileNoSuchFileError || error.code == NSFileReadNoSuchFileError)
      {
        fileSize = 0
      }
      let isRecording = self.assetWriter.status == .writing
      return RecordingStatus(
        isRecording: isRecording,
        isPaused: isRecording && self.videoTrack?.isPaused == true,
        duration: self.videoTrack?.duration ?? .zero,
        fileSize: fileSize)
    }
  }

  func initializeVideoTrack(withSettings settings: [String: Any]) throws {
    guard !settings.isEmpty else {
      throw RecordingError.invalidOutputSettings(mediaType: .video)
    }
    guard videoTrack == nil else {
      throw RecordingError.trackAlreadyConfigured(mediaType: .video)
    }
    guard assetWriter.canApply(outputSettings: settings, forMediaType: .video) else {
      throw RecordingError.invalidOutputSettings(mediaType: .video)
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
      throw RecordingError.trackAlreadyConfigured(mediaType: .audio)
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
  /// Returns once recording has successfully started. Read ``fileURL`` for the destination, or use the ``RecordingResult`` delivered to `onFinished` after finalization.
  /// The recording continues after this method returns. Completion or failure is reported through the callbacks.
  /// Callbacks run on the recorder's owning serial queue. Move UIKit work to the main actor.
  ///
  /// - Parameter onFinished: Called when recording finishes and the file has been written, including when a configured duration or file-size limit is reached.
  /// - Parameter onError: Called when an unexpected error occurs while recording.
  /// - Parameter onPaused: Called when recording pauses.
  /// - Parameter onResumed: Called when recording resumes.
  /// - Throws: If this recorder has already been started or recording fails to start.
  public func start(
    onFinished: @escaping (RecordingResult) -> Void,
    onError: @escaping (any Error) -> Void,
    onPaused: (() -> Void)? = nil,
    onResumed: (() -> Void)? = nil
  ) async throws {
    return try await queue.perform {
      guard self.assetWriter.status == .unknown, !self.isFinishing else {
        throw RecordingError.alreadyStarted
      }

      // Notify about to start
      self.didNotifyDelegateOfStart = true
      self.delegate.onRecorderWillStart()

      // Prepare the AssetWriter for writing to the video file
      let success = self.assetWriter.startWriting()
      guard success else {
        self.notifyDelegateOfStop()
        throw self.assetWriter.error ?? RecordingError.writerCouldNotStart
      }
      logger.info("AssetWriter started writing to \(self.fileURL.path)!")

      // Assign callbacks
      self.onFinished = onFinished
      self.onError = onError
      self.onPaused = onPaused
      self.onResumed = onResumed

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
  /// Once the recording has actually stopped and the file is written, the `onFinished` callback passed to `start` is called. Returning from this method does not mean the file is finalized.
  public func stop() async {
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
  /// the `onPaused` callback passed to
  /// ``FrameRecorder/start(onFinished:onError:onPaused:onResumed:)`` will be called.
  public func pause() async {
    return await queue.perform {
      // Pause each track
      self.videoTrack?.pause()
      self.audioTrack?.pause()

      // Notify listener
      self.onPaused?()
    }
  }

  /// Requests the currently paused Video recording
  /// to be resumed.
  /// Once the recording has actually been resumed,
  /// the `onResumed` callback passed to
  /// ``FrameRecorder/start(onFinished:onError:onPaused:onResumed:)`` will be called.
  public func resume() async {
    return await queue.perform {
      // Resume each track
      self.videoTrack?.resume()
      self.audioTrack?.resume()

      // Notify listener
      self.onResumed?()
    }
  }

  /// Cancels the current recording and deletes
  /// the video file.
  ///
  /// Cancels writing on the recorder queue and removes the file. Completion callbacks are suppressed; file removal errors propagate to the caller. Throws if no recording is active.
  public func cancel() async throws {
    return try await queue.perform {
      guard self.assetWriter.status == .writing else {
        throw RecordingError.notRecording
      }
      // Clear callbacks so they don't fire during cancellation
      self.onFinished = nil
      self.onError = nil
      self.onPaused = nil
      self.onResumed = nil
      // Cancel the writing session
      self.isFinishing = true
      self.assetWriter.cancelWriting()
      self.notifyDelegateOfStop()
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
        } catch {
          logger.error("Failed to append buffer to \(type.rawValue) track! \(error)")
          self.fail(self.assetWriter.error ?? error)
          return
        }

        // If we failed to write the frames, stop the Recording
        if self.assetWriter.status == .failed {
          logger.error("Failed to write buffer: \(self.assetWriter.error)")
          let error = self.assetWriter.error ?? RecordingError.writerCouldNotAppend
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

        // When all tracks (video + audio) are finished (via `stop`),
        // finish the Recording.
        if self.isFinished {
          self.finish(reason: .stopped)
        }
      })
  }

  private func reachedFileSizeLimit() -> Bool {
    if let maxFileSize = settings.maxFileSize {
      // Check if video size >= max target file size
      if let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
        let bytes = attributes[.size] as? NSNumber, bytes.int64Value >= maxFileSize
      {
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
        throw RecordingError.trackUnavailable(mediaType: .audio)
      }
      return audioTrack
    case .video:
      guard let videoTrack else {
        throw RecordingError.trackUnavailable(mediaType: .video)
      }
      return videoTrack
    }
  }

  private func finish(reason: RecordingFinishedReason) {
    guard !isFinishing else { return }
    guard let lastVideoTimestamp = videoTrack?.lastTimestamp else {
      fail(RecordingError.noVideoFrames)
      return
    }
    guard assetWriter.status == .writing else {
      fail(assetWriter.error ?? RecordingError.writerNotWriting)
      return
    }
    isFinishing = true
    assetWriter.endSession(atSourceTime: lastVideoTimestamp)
    assetWriter.finishWriting {
      self.queue.async(
        execute: DispatchWorkItem {
          if self.assetWriter.status == .completed {
            self.onFinished?(RecordingResult(fileURL: self.fileURL, reason: reason))
          } else {
            self.onError?(self.assetWriter.error ?? RecordingError.writerCouldNotFinish)
          }
          self.clearCallbacks()
          self.notifyDelegateOfStop()
        })
    }
  }

  private func fail(_ error: Error) {
    guard !isFinishing else { return }
    isFinishing = true
    if assetWriter.status == .writing { assetWriter.cancelWriting() }
    onError?(error)
    clearCallbacks()
    notifyDelegateOfStop()
  }

  private func notifyDelegateOfStop() {
    guard didNotifyDelegateOfStart else { return }
    didNotifyDelegateOfStart = false
    delegate.onRecorderDidStop()
  }

  private func clearCallbacks() {
    onFinished = nil
    onError = nil
    onPaused = nil
    onResumed = nil
  }
}
