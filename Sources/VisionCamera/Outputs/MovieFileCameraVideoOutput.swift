///
/// MovieFileCameraVideoOutput.swift
/// VisionCamera
/// Copyright © 2025 Marc Rousavy @ Margelo
///

import AVFoundation
import Foundation

/// The ``MovieFileCameraVideoOutput`` records videos with `AVCaptureMovieFileOutput`.
///
/// It implements ``CameraVideoOutput``. Use ``CameraVideoFrameOutput`` for persistent recordings that continue across Camera switching.
public final class MovieFileCameraVideoOutput: CameraVideoOutput, NativeCameraOutput {
  private let queue = DispatchQueue(label: "com.margelo.camera.video")
  private let options: VideoOutputOptions
  private let fileType: RecorderFileType
  /// The media type of the content being streamed
  /// by this ``CameraOutput``.
  public let mediaType: MediaType = .video
  /// The underlying AVFoundation output connected to the Camera Session.
  public let output: AVCaptureMovieFileOutput
  /// Whether the Camera Session must connect an audio input to this output.
  public var requiresAudioInput: Bool {
    return options.enableAudio == true
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

  /// The stream type used when negotiating this output's target resolution.
  public var streamType: StreamType = .video
  /// The resolution rule negotiated with the other outputs and the connection's ordered ``Constraint``s.
  public var targetResolution: ResolutionRule {
    return .closestTo(options.targetResolution)
  }

  /// Creates a Camera output with the given options.
  public init(options: VideoOutputOptions) {
    self.output = AVCaptureMovieFileOutput()
    self.options = options
    self.fileType = options.fileType ?? .mov
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
  public func configure(config: OutputConfiguration) {
    guard let connection = output.connection(with: .video) else {
      return
    }
    try? connection.setOrientation(outputOrientation)
    try? connection.setMirrorMode(config.mirrorMode)

    if let targetBitRate = options.targetBitRate {
      self.setBitRate(bitRate: Int(targetBitRate), for: connection)
    }
  }

  /// Get all supported ``VideoCodec``s this
  /// ``CameraVideoOutput`` currently can record in.
  ///
  /// This method must be called after the ``CameraVideoOutput``
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
    return output.availableVideoCodecTypes.map { VideoCodec(avCodec: $0) }
  }

  /// Set the output settings for this video output.
  /// This method must be called after the output has been
  /// attached to the Camera Session, and before
  /// ``MovieFileCameraVideoOutput/createRecorder(settings:)``.
  ///
  /// Settings are applied on the output's serial queue. Unsupported codecs and incompatible codec/bit-rate settings throw.
  public func setOutputSettings(settings: VideoOutputSettings) async throws {
    return try await queue.perform {
      guard let connection = self.output.connection(with: .video) else {
        throw CameraError(
          message:
            "Cannot set output settings when VideoOutput is not yet connected to the CameraSession!"
        )
      }

      if let codec = settings.codec {
        if codec.isRawCodec {
          guard self.options.targetBitRate == nil else {
            throw CameraError(
              message:
                "Cannot set bit-rate when recording in a RAW codec! (\(codec))")
          }
        }

        let avCodec = try codec.toAVVideoCodecType()
        guard self.output.availableVideoCodecTypes.contains(avCodec) else {
          throw CameraError(
            message:
              "Video codec \(codec) is not supported by this device! "
              + "Supported codecs: \(self.output.availableVideoCodecTypes.map(\.rawValue))")
        }

        if let bitRate = self.options.targetBitRate {
          self.setOutputSettings(
            bitRate: Int(bitRate),
            codec: avCodec,
            for: connection)
        } else {
          self.setOutputSettings(
            codec: avCodec,
            for: connection)
        }
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
  /// Creation runs on the output's serial queue. Invalid location metadata and file-system setup errors propagate to the caller. Connect this output to a Camera Session before starting the recorder.
  public func createRecorder(settings: RecorderSettings) async throws -> any Recorder {
    return try await queue.perform {
      if let location = settings.location {
        let metadataItem = try location.toAVMutableMetadataItem()
        self.setMetadataTag(metadataItem)
      }
      return try VideoRecorder(
        videoOutput: self.output,
        queue: self.queue,
        fileType: self.fileType,
        settings: settings)
    }
  }

  private func setBitRate(bitRate: Int, for connection: AVCaptureConnection) {
    let currentSettings = output.outputSettings(for: connection)
    let currentCodec = currentSettings[AVVideoCodecKey] as? AVVideoCodecType ?? AVVideoCodecType.hevc

    setOutputSettings(bitRate: bitRate, codec: currentCodec, for: connection)
  }

  private func setOutputSettings(bitRate: Int, codec: AVVideoCodecType, for connection: AVCaptureConnection) {
    let supportedKeys = output.supportedOutputSettingsKeys(for: connection)
    guard supportedKeys.contains(AVVideoCompressionPropertiesKey) else {
      logger.error(
        "Setting `AVVideoCompressionPropertiesKey` is not supported - cannot use custom bit-rate!")
      return
    }

    let settings: [String: Any] = [
      AVVideoCodecKey: codec,
      AVVideoCompressionPropertiesKey: [
        AVVideoAverageBitRateKey: bitRate
          // ..the remaining AVVideoCompressionPropertiesKey values will be filled by AVFoundation
      ],
    ]
    output.setOutputSettings(settings, for: connection)
  }

  private func setOutputSettings(codec: AVVideoCodecType, for connection: AVCaptureConnection) {
    let settings: [String: Any] = [AVVideoCodecKey: codec]
    output.setOutputSettings(settings, for: connection)
  }
}
