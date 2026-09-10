///
/// MovieFileVideoOutput.swift
/// VisionCamera
/// Copyright © 2025 Marc Rousavy @ Margelo
///

import AVFoundation
import Foundation

/// The ``VideoFrameOutput`` records Camera frames with `AVAssetWriter`.
///
/// It implements ``VideoOutput`` and supports persistent recordings that continue across Camera switching.
public final class VideoFrameOutput: VideoOutput, NativeCameraOutput, RecorderDelegate {
  private let delegate: FrameDelegate
  private let options: VideoOutputOptions
  private let queue: DispatchQueue
  private let videoQueue: DispatchQueue
  private var audioSession: AudioSession? = nil
  /// The media type of the content being streamed
  /// by this ``CameraOutput``.
  public let mediaType: MediaType = .video
  /// Returns `false` because this output manages its audio capture session separately when ``VideoOutputOptions/enableAudio`` is enabled.
  public let requiresAudioInput: Bool = false
  /// Whether the Camera Session must select an active depth format for this output.
  public let requiresDepthFormat: Bool = false
  /// The underlying AVFoundation output connected to the Camera Session.
  public let output: AVCaptureVideoDataOutput
  private var recorders = WeakArray<FrameRecorder>()
  private let fileType: RecorderFileType

  /// The stream type used when negotiating this output's target resolution.
  public var streamType: StreamType = .video
  /// The resolution rule negotiated with the other outputs and the connection's ordered ``Constraint``s.
  public var targetResolution: ResolutionRule {
    return .closestTo(options.targetResolution)
  }

  /// Gets or sets the output orientation of this ``CameraOutput``.
  ///
  /// Individual implementations of ``CameraOutput``
  /// may choose different strategies for implementing
  /// output orientation, for example:
  /// - A Photo output might apply orientation via EXIF flags.
  /// - A Video output might apply orientation via track transform metadata.
  /// - A Preview output might apply orientation via view transforms.
  /// - A Frame output might not apply orientation and only pass it as a
  /// property via the `Frame` object, unless explicitly configured to
  /// physically rotate buffers.
  public var outputOrientation: CameraOrientation = .up {
    didSet {
      guard let connection = output.connection(with: .video) else { return }
      // TODO: Should we apply that within the CameraSession's DispatchQueue? Batch it?
      try? connection.setOrientation(outputOrientation)
    }
  }
  /// The resolution that the underlying capture pipeline has resolved
  /// this ``CameraOutput`` to, in sensor-native (un-rotated) pixels,
  /// or `nil` if the output has not yet been connected to a
  /// ``CameraSession``.
  ///
  /// The selected ``Size`` may differ from the requested
  /// ``Size`` (e.g. from ``PhotoOutputOptions/targetResolution``),
  /// as the ``CameraSession`` negotiates resolutions across
  /// attached ``CameraOutput``s, connected ``CameraDevice``
  /// capabilities, and enabled ``Constraint``s.
  ///
  /// For outputs that are not pixel-based (e.g. metadata-only outputs),
  /// this reports the resolution of the upstream video stream feeding
  /// the output, or `nil` if no video input is attached.
  public var currentResolution: Size? {
    guard let connection = output.connection(with: .video) else { return nil }
    return connection.inputStreamResolution
  }

  private var videoCodec: AVVideoCodecType?
  /// Creates a Camera output with the given options.
  public init(options: VideoOutputOptions = .init()) {
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

  /// Applies mirroring and orientation settings to this output's current connection.
  ///
  /// ``CameraSession`` calls this method within its configuration batch. Native output integrations must call it on the owning session's configuration queue.
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

  /// Get all supported ``VideoCodec``s this
  /// ``VideoOutput`` currently can record in.
  ///
  /// This method must be called after the ``VideoOutput``
  /// has been attached to a Camera Session.
  ///
  /// - Throws: This method throws if you call it before this output
  /// is attached to a Camera Session (via `configure(...)`)
  ///
  /// - Throws: If the output is not connected to a Camera Session.
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

  /// Set the output settings for this video output.
  /// This method must be called after the output has been
  /// attached to the Camera Session, and before
  /// ``VideoFrameOutput/makeRecorder(settings:)``.
  ///
  /// Settings are applied on the output's serial queue. Unsupported codecs and incompatible codec/bit-rate settings throw.
  public func setOutputSettings(settings: VideoOutputSettings) async throws {
    try await queue.perform {
      if let codec = settings.codec {
        let nativeCodec = try codec.toAVVideoCodecType()
        let availableCodecs = self.output.availableVideoCodecTypesForAssetWriter(writingTo: self.fileType.toAVFileType())
        guard availableCodecs.contains(nativeCodec) else {
          throw CameraError(message: "VideoOutput does not support codec \(codec).")
        }
        guard !codec.isRawCodec || self.options.targetBitRate == nil else {
          throw CameraError(message: "Cannot use a custom bit rate with a RAW codec.")
        }
        self.videoCodec = nativeCodec
      }
    }
  }

  /// Creates and prepares a new ``Recorder``
  /// instance with the given ``RecorderSettings``.
  ///
  /// The ``Recorder`` will record to the configured
  /// file path, or to a temporary file if no path was provided.
  /// The ``Recorder``'s file paths are filesystem paths,
  /// not `file://` URLs.
  /// It can only record once.
  ///
  /// If you want to create a second recording,
  /// you must create a new ``Recorder``.
  ///
  /// Create the recorder after connecting this output to a configured Camera Session. Creation runs on the output's serial queue and can throw if a video connection, encoding settings, or audio input is unavailable.
  public func makeRecorder(settings: RecorderSettings) async throws -> any Recorder {
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

  /// Starts the audio capture session on the output's queue before a recorder starts.
  public func onRecorderWillStart() {
    queue.async { self.audioSession?.start() }
  }

  /// Stops the audio capture session on the output's queue once no recorder is still recording.
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
