///
/// MovieFileVideoOutput.swift
/// VisionCamera
/// Copyright © 2025 Marc Rousavy @ Margelo
///

import AVFoundation
import Foundation

/// The ``MovieFileVideoOutput`` records videos with `AVCaptureMovieFileOutput`.
///
/// It implements ``VideoOutput``. Use ``VideoFrameOutput`` for persistent recordings that continue across Camera switching.
public final class MovieFileVideoOutput: VideoOutput, NativeCameraOutput {
  private let queue = DispatchQueue(label: "com.margelo.camera.video")
  private let recordingCoordinator = MovieFileRecordingCoordinator()
  private let options: VideoOutputOptions
  /// The media type of the content being streamed
  /// by this ``CameraOutput``.
  public let mediaType: MediaType = .video
  /// The underlying AVFoundation output connected to the Camera Session.
  public let output: AVCaptureMovieFileOutput
  /// Whether the Camera Session must connect an audio input to this output.
  public var requiresAudioInput: Bool {
    return options.isAudioEnabled
  }
  /// Whether the Camera Session must select an active depth format for this output.
  public let requiresDepthFormat: Bool = false
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
  ///
  /// When disconnected, the requested orientation is applied and validated at the next session configuration.
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
  /// The selected `CGSize` may differ from the requested
  /// `CGSize` (e.g. from ``PhotoOutputOptions/targetResolution``),
  /// as the ``CameraSession`` negotiates resolutions across
  /// attached ``CameraOutput``s, connected ``CameraDevice``
  /// capabilities, and enabled ``Constraint``s.
  ///
  /// For outputs that are not pixel-based (e.g. metadata-only outputs),
  /// this reports the resolution of the upstream video stream feeding
  /// the output, or `nil` if no video input is attached.
  public var currentResolution: CGSize? {
    guard let connection = output.connection(with: .video) else { return nil }
    return connection.inputStreamResolution
  }

  /// The stream type used when negotiating this output's target resolution.
  public let streamType: StreamType = .video
  /// The resolution rule negotiated with the other outputs and the connection's ordered ``Constraint``s.
  public var targetResolution: ResolutionRule {
    return .closest(to: options.targetResolution)
  }

  /// Creates a Camera output with the given options.
  public init(options: VideoOutputOptions = .init()) {
    self.output = AVCaptureMovieFileOutput()
    self.options = options
    self.setMetadataTag(.libraryTag)
  }

  private func setMetadataTag(_ tag: AVMetadataItem) {
    // Get metadata (or empty array)
    var metadata = self.output.metadata ?? []
    // Remove all items with the same key
    metadata.removeAll { item in
      guard let itemKey = item.key as? NSString,
        let tagKey = tag.key as? NSString
      else { return false }
      return item.keySpace == tag.keySpace && itemKey == tagKey
    }
    // add the new tag
    metadata.append(tag)
    self.output.metadata = metadata
  }

  /// Applies mirroring and orientation settings to this output's current connection.
  ///
  /// ``CameraSession`` calls this method within its configuration batch. Native output integrations must call it on the owning session's configuration queue.
  /// - Throws: If the connection does not support the requested orientation or mirroring.
  public func configure(_ config: OutputConfiguration) throws {
    guard let connection = output.connection(with: .video) else {
      return
    }
    try connection.setOrientation(outputOrientation)
    try connection.setMirrorMode(config.mirrorMode)
  }

  /// Get all supported `AVVideoCodecType` values this
  /// ``VideoOutput`` currently can record in.
  ///
  /// This method must be called after the ``VideoOutput``
  /// has been attached to a Camera Session.
  ///
  /// - Throws: This method throws if you call it before this output
  /// is attached to a Camera Session (via ``CameraSession/configure(_:configuration:)``).
  ///
  /// The query runs on the output's serial queue.
  public func supportedVideoCodecs() async throws -> [AVVideoCodecType] {
    return try await queue.perform {
      guard self.output.connection(with: .video) != nil else {
        throw RecordingError.outputNotConnected
      }
      return self.output.availableVideoCodecTypes
    }
  }

  /// Selects a supported native codec before creating a recorder.
  ///
  /// - Throws: If the output is disconnected or the codec or bit rate is unsupported.
  public func setVideoCodec(_ codec: AVVideoCodecType) async throws {
    try await queue.perform {
      guard let connection = self.output.connection(with: .video) else {
        throw RecordingError.outputNotConnected
      }
      guard self.output.availableVideoCodecTypes.contains(codec) else {
        throw RecordingError.unsupportedCodec(codec)
      }
      try self.applyEncodingSettings(codec: codec, for: connection)
    }
  }

  /// Creates and prepares a new ``Recorder``
  /// instance with the given ``RecorderSettings``.
  ///
  /// The ``Recorder`` will record to the configured
  /// file URL, or to a temporary file if no URL was provided.
  /// It can only record once.
  ///
  /// If you want to create a second recording,
  /// you must create a new ``Recorder``.
  ///
  /// Creation runs on the output's serial queue. Connect this output to a Camera Session first. Unsupported encoding settings, invalid metadata, and file-system errors throw.
  public func makeRecorder(settings: RecorderSettings = .init()) async throws -> VideoRecorder {
    return try await queue.perform {
      try settings.validate()
      guard let connection = self.output.connection(with: .video) else {
        throw RecordingError.outputNotConnected
      }
      try self.applyEncodingSettings(for: connection)
      return try VideoRecorder(
        videoOutput: self.output,
        queue: self.queue,
        coordinator: self.recordingCoordinator,
        fileType: .mov,
        settings: settings)
    }
  }

  private func applyEncodingSettings(codec: AVVideoCodecType? = nil, for connection: AVCaptureConnection) throws {
    guard codec != nil || options.bitRate != nil else { return }
    var settings: [String: Any] = codec.map { [AVVideoCodecKey: $0] } ?? output.outputSettings(for: connection)
    if let bitRate = options.bitRate {
      guard output.supportedOutputSettingsKeys(for: connection).contains(AVVideoCompressionPropertiesKey) else {
        throw RecordingError.customBitRateUnsupported
      }
      try options.validateBitRate(for: codec ?? settings[AVVideoCodecKey] as? AVVideoCodecType)
      var compression = settings[AVVideoCompressionPropertiesKey] as? [String: Any] ?? [:]
      compression[AVVideoAverageBitRateKey] = bitRate
      settings[AVVideoCompressionPropertiesKey] = compression
    }
    if !settings.isEmpty { output.setOutputSettings(settings, for: connection) }
  }
}
