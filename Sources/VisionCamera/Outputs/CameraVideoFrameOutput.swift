///
/// MovieFileCameraVideoOutput.swift
/// VisionCamera
/// Copyright © 2025 Marc Rousavy @ Margelo
///

import AVFoundation
import Foundation

public final class CameraVideoFrameOutput: CameraVideoOutput, NativeCameraOutput, RecorderDelegate {
  private let delegate: FrameDelegate
  private let options: VideoOutputOptions
  private let queue: DispatchQueue
  private let videoQueue: DispatchQueue
  private var audioSession: AudioSession? = nil
  public let mediaType: MediaType = .video
  public let requiresAudioInput: Bool = false
  public let requiresDepthFormat: Bool = false
  public let output: AVCaptureVideoDataOutput
  private var recorders = WeakArray<FrameRecorder>()
  private let fileType: RecorderFileType

  public var streamType: StreamType = .video
  public var targetResolution: ResolutionRule {
    return .closestTo(options.targetResolution)
  }

  public var outputOrientation: CameraOrientation = .up {
    didSet {
      guard let connection = output.connection(with: .video) else { return }
      // TODO: Should we apply that within the CameraSession's DispatchQueue? Batch it?
      try? connection.setOrientation(outputOrientation)
    }
  }
  public var currentResolution: Size? {
    guard let connection = output.connection(with: .video) else { return nil }
    return connection.inputStreamResolution
  }

  private var videoCodec: AVVideoCodecType?
  public init(options: VideoOutputOptions) {
    self.output = AVCaptureVideoDataOutput()
    self.delegate = FrameDelegate()
    self.options = options
    self.fileType = options.fileType ?? .mov
    self.queue = DispatchQueue(
      label: "com.margelo.camera.video-frame",
      qos: .userInteractive,
      attributes: [],
      autoreleaseFrequency: .inherit,
      target: nil)
    self.videoQueue = DispatchQueue(
      label: "com.margelo.camera.video-frame.video",
      qos: .utility)

    // Set up our `delegate`
    output.setSampleBufferDelegate(delegate, queue: videoQueue)
    // Set the pixel format to the device native format.
    output.videoSettings = [:]
    // Queue up Frames if there are hiccups in AVAssetWriter so we don't lose Frames.
    output.alwaysDiscardsLateVideoFrames = false
    // The session configures the video resolution, we don't want to downscale here.
    output.automaticallyConfiguresOutputBufferDimensions = false
    if #available(iOS 26.0, *) {
      // We only use this output for recording, allowing it to start deferred makes the session start faster.
      if output.isDeferredStartSupported {
        output.isDeferredStartEnabled = true
      }
      // Allow capturing HDR
      output.preservesDynamicHDRMetadata = true
    }
    // set the delegate to append to the Recorder
    delegate.onFrame = { [weak self] buffer, timestamp, orientation, isMirrored in
      guard let self else { return }
      self.onFrame(buffer, type: .video)
    }
  }

  public func configure(config: OutputConfiguration) {
    // TODO: Set orientation via video metadata flags to avoid physically rotating buffers.
    //       The problem with that is that we need to support switching Camera devices on the fly,
    //       which rotates buffer later on somehow.
    guard let connection = output.connection(with: .video) else {
      return
    }
    try? connection.setMirrorMode(config.mirrorMode)
    try? connection.setOrientation(outputOrientation)
  }

  public func getSupportedVideoCodecs() throws -> [VideoCodec] {
    guard output.connection(with: .video) != nil else {
      throw CameraError(
        message:
          "Cannot call `getSupportedVideoCodecs()` when VideoOutput is not yet connected to the CameraSession!"
      )
    }
    let availableCodecs = output.availableVideoCodecTypesForAssetWriter(writingTo: fileType.toAVFileType())
    return availableCodecs.map { VideoCodec(avCodec: $0) }
  }

  public func setOutputSettings(settings: VideoOutputSettings) async throws {
    try await queue.perform {
      if let codec = settings.codec {
        let nativeCodec = try codec.toAVVideoCodecType()
        let availableCodecs = self.output.availableVideoCodecTypesForAssetWriter(writingTo: self.fileType.toAVFileType())
        guard availableCodecs.contains(nativeCodec) else {
          throw CameraError(message: "VideoOutput does not support codec \(codec.stringValue).")
        }
        guard !codec.isRawCodec || self.options.targetBitRate == nil else {
          throw CameraError(message: "Cannot use a custom bit rate with a RAW codec.")
        }
        self.videoCodec = nativeCodec
      }
    }
  }

  public func createRecorder(settings: RecorderSettings) async throws -> any Recorder {
    return try await queue.perform {
      // 1. Create AVAssetWriter Recorder
      let clock = try self.getMasterClock()
      let recorder = try FrameRecorder(
        orientation: .up,
        masterClock: clock,
        fileType: self.fileType,
        settings: settings,
        delegate: self)
      // 2. Initialize its video track immediately
      guard
        var videoSettings = self.output.recommendedVideoSettingsForAssetWriter(
          writingTo: self.fileType.toAVFileType())
      else {
        throw CameraError(
          message: "Cannot initialize Recorder - no available video settings were found!")
      }
      if let codec = self.videoCodec { videoSettings[AVVideoCodecKey] = codec }
      if let bitRate = self.options.targetBitRate {
        var compression = videoSettings[AVVideoCompressionPropertiesKey] as? [String: Any] ?? [:]
        compression[AVVideoAverageBitRateKey] = bitRate
        videoSettings[AVVideoCompressionPropertiesKey] = compression
      }
      try recorder.initializeVideoTrack(withSettings: videoSettings)

      // 3. Set video metadata
      if #available(iOS 26.0, *) {
        // 2.1.a. Set video timescale if available. This avoids audio/video sync-drift in super long videos.
        recorder.setTimescale(self.output.recommendedMediaTimeScaleForAssetWriter)
        let codec = self.getCurrentVideoCodec()
        if let metadata = self.output.recommendedMovieMetadata(
          forVideoCodecType: codec, assetWriterOutputFileType: self.fileType.toAVFileType())
        {
          // 2.2. Set metadata if available
          try recorder.setMetadata(metadata, settings: settings)
        } else {
          try recorder.setMetadata([], settings: settings)
        }
      } else {
        // 2.1.b. Set metadata before iOS 26.0
        try recorder.setMetadata([], settings: settings)
      }

      // 4. If we enable audio, also initialize the audio track
      if self.options.enableAudio == true {
        let audioSession = try self.getOrCreateAudioSession()
        let audioSettings = audioSession.output.recommendedAudioSettingsForAssetWriter(
          writingTo: self.fileType.toAVFileType())
        let audioFormat = audioSession.input.device.activeFormat
        try recorder.initializeAudioTrack(
          withSettings: audioSettings, format: audioFormat.formatDescription)
      }

      // 5. Add it to our state and return
      self.recorders.append(recorder)
      return recorder
    }
  }

  public func onRecorderWillStart() {
    queue.async { self.audioSession?.start() }
  }

  public func onRecorderDidStop() {
    queue.async {
      let hasActiveRecorders = self.recorders.values().contains { $0.isRecording }
      if !hasActiveRecorders { self.audioSession?.stop() }
    }
  }

  private func getCurrentVideoCodec() -> AVVideoCodecType {
    return videoCodec ?? .hevc
  }

  private func getMasterClock() throws -> CMClock {
    guard let connection = output.connection(with: .video) else {
      throw CameraError(
        message: "The VideoOutput is not yet connected to the CameraSession!")
    }
    guard let inputPort = connection.inputPorts.first else {
      throw CameraError(message: "The VideoOutput is not yet connected to an input!")
    }
    guard let clock = inputPort.clock else {
      throw CameraError(
        message: "The VideoOutput's connected input device does not have a master clock!")
    }
    return clock
  }

  private func getOrCreateAudioSession() throws -> AudioSession {
    if let audioSession {
      // We already created an Audio AVCaptureSession, return it
      return audioSession
    }
    // 1. Create session
    let audioSession = try AudioSession()
    // 2. Add on frame listener
    audioSession.setOnFrameListener { [weak self] buffer, timestamp in
      guard let self else { return }
      self.onFrame(buffer, type: .audio)
    }
    // 3. Return it!
    self.audioSession = audioSession
    return audioSession
  }

  private func onFrame(_ buffer: CMSampleBuffer, type: TrackType) {
    queue.async {
      for recorder in self.recorders.values() {
        recorder.append(buffer: buffer, ofType: type)
      }
    }
  }
}
