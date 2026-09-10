///
/// FrameOutput.swift
/// VisionCamera
/// Copyright © 2025 Marc Rousavy @ Margelo
///

import AVFoundation
import Foundation

/// The ``FrameOutput`` allows synchronously streaming
/// ``Frame``s from the Camera, aka "Frame Processing".
///
/// ```swift
/// let frameOutput = FrameOutput()
/// await frameOutput.setFrameHandler { frame in
///   print(frame.width as Any, frame.height as Any)
/// }
/// ```
public final class FrameOutput: CameraOutput, NativeCameraOutput {
  private let delegate: FrameDelegate
  private let queue: DispatchQueue
  private let orientationState = OutputOrientationState()
  private let options: FrameOutputOptions
  /// The media type of the content being streamed
  /// by this ``CameraOutput``.
  public let mediaType: MediaType = .video
  /// Whether the Camera Session must connect an audio input to this output.
  public let requiresAudioInput: Bool = false
  /// Whether the Camera Session must select an active depth format for this output.
  public let requiresDepthFormat: Bool = false
  /// The underlying AVFoundation output connected to the Camera Session.
  public let output: AVCaptureVideoDataOutput
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
      orientationState.setOrientation(outputOrientation)
      guard let connection = output.connection(with: .video) else { return }
      if options.rotatesBuffers {
        // TODO: Should we apply that within the CameraSession's DispatchQueue? Batch it?
        try? connection.setOrientation(outputOrientation)
      }
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
  public init(options: FrameOutputOptions = .init()) {
    self.output = AVCaptureVideoDataOutput()
    self.delegate = FrameDelegate()
    self.options = options
    self.queue = DispatchQueue(
      label: "com.margelo.camera.frame",
      qos: .userInteractive,
      attributes: [],
      autoreleaseFrequency: .inherit,
      target: nil)

    // Set up our `delegate`
    output.setSampleBufferDelegate(delegate, queue: queue)
    // Configure `videoSettings`
    output.videoSettings = [:]
    // If the pipeline stalls, drop frames to avoid blowing up RAM
    output.alwaysDiscardsLateVideoFrames = options.discardsLateFrames
    // The session configures the video resolution, we don't want to downscale here by default.
    output.automaticallyConfiguresOutputBufferDimensions = false
    if #available(iOS 26.0, *), output.isDeferredStartSupported {
      // Deferred start allows the Session to delay this output's startup in favor
      // of preview-related outputs to make preview appear faster.
      output.isDeferredStartEnabled = options.allowsDeferredStart
    }
    // TODO: Add a flag called `allowBufferResizing` and probably get rid of `usesPreviewSizedBuffers`
    //       If `allowBufferResizing` is true, we can set `.videoSettings`/dimensions here to `options.targetResolution`
    //       and `targetResolution` to `.any` (to not participate in resolution negotiations).
    //       If `allowBufferResizing` is false, we don't set `.videoSettings` ("native" resolution), and reflect our
    //       target resolution via `targetResolution` to participate in resolution negotiations.
    if #available(iOS 17.0, *), options.usesPreviewSizedBuffers {
      output.deliversPreviewSizedOutputBuffers = true
    }
    if #available(iOS 26.0, *) {
      // We don't need HDR metadata, as that's only useful for encoders.
      output.preservesDynamicHDRMetadata = false
    }
  }

  /// Applies the requested pixel format, mirroring, and orientation to the current connection.
  ///
  /// - Throws: If the requested pixel format, buffer rotation, or matrix delivery is unsupported.
  ///
  /// ``CameraSession`` calls this method within its configuration batch. Native output integrations must call it on the owning session's configuration queue.
  public func configure(_ config: OutputConfiguration) throws {
    orientationState.setMirrorMode(config.mirrorMode)

    guard let connection = output.connection(with: .video) else {
      return
    }
    output.videoSettings = try options.pixelFormat.videoSettings(availablePixelFormats: output.availableVideoPixelFormatTypes)
    if options.usesPreviewSizedBuffers {
      guard #available(iOS 17.0, *) else {
        throw ConfigurationError.previewSizedBuffersRequireIOS17
      }
    }
    if options.rotatesBuffers {
      try connection.setOrientation(outputOrientation)
      try connection.setMirrorMode(config.mirrorMode)
    }
    if options.isCameraIntrinsicMatrixDeliveryEnabled {
      guard connection.isCameraIntrinsicMatrixDeliverySupported else {
        throw ConfigurationError.intrinsicMatrixDeliveryUnsupported
      }
      connection.isCameraIntrinsicMatrixDeliveryEnabled = true
    }
  }

  func getMediaSampleMetadata(
    at timestamp: CMTime,
    orientation bufferOrientation: CameraOrientation,
    isMirrored isBufferMirrored: Bool
  ) -> MediaSampleMetadata {
    return orientationState.metadata(
      at: timestamp, bufferOrientation: bufferOrientation, isBufferMirrored: isBufferMirrored)
  }

  /// Adds a callback that calls the given `onFrame` function
  /// every time the Camera produces a new ``Frame``.
  ///
  /// Registration and callback delivery are serialized on this output's owning queue. Pass `nil` to remove the callback. This method returns after registration is applied. Move UIKit work to the main actor.
  public func setFrameHandler(_ onFrame: ((Frame) -> Void)?) async {
    await queue.perform {
      if let onFrame {
        self.delegate.onFrame = { [weak self] (sampleBuffer, timestamp, bufferOrientation, isBufferMirrored) in
          guard let self else { return }
          // Prepare Frame + Metadata
          let metadata = self.getMediaSampleMetadata(
            at: timestamp,
            orientation: bufferOrientation,
            isMirrored: isBufferMirrored)
          let frame = Frame(
            sampleBuffer: sampleBuffer,
            metadata: metadata)
          // Deliver the sample on the output queue.
          onFrame(frame)
        }
      } else {
        self.delegate.onFrame = nil
      }
    }
  }

  /// Adds a callback that gets called when a ``Frame`` has been dropped.
  /// This often happens if your Frame Callback is taking longer than a frame interval.
  ///
  /// Registration and callback delivery are serialized on this output's owning queue. Pass `nil` to remove the callback. This method returns after registration is applied. Move UIKit work to the main actor.
  public func setFrameDropHandler(_ onFrameDropped: ((FrameDroppedReason) -> Void)?) async {
    await queue.perform {
      if let onFrameDropped {
        self.delegate.onFrameDropped = { sampleBuffer in
          guard let attachment = sampleBuffer.attachments[.droppedFrameReason] else {
            return
          }
          let reason = FrameDroppedReason(sampleBufferReason: attachment)
          onFrameDropped(reason)
        }
      } else {
        self.delegate.onFrameDropped = nil
      }
    }
  }
}
