///
/// DepthOutput.swift
/// VisionCamera
/// Copyright © 2025 Marc Rousavy @ Margelo
///

import AVFoundation
import Foundation

/// The ``DepthOutput`` allows synchronously streaming
/// ``Depth`` Frames from the Camera, aka "Depth Frame Processing".
///
/// ```swift
/// let depthOutput = DepthOutput()
/// await depthOutput.setDepthHandler { depth in
///   print(depth.width, depth.height)
/// }
/// ```
public final class DepthOutput: CameraOutput, NativeCameraOutput {
  private let delegate: DepthFrameDelegate
  private let queue: DispatchQueue
  private let options: DepthOutputOptions
  private var mirrorMode: MirrorMode = .auto
  private var metadataOrientation: CameraOrientation = .up
  /// The media type of the content being streamed
  /// by this ``CameraOutput``.
  public let mediaType: MediaType = .depth
  /// Whether the Camera Session must connect an audio input to this output.
  public let requiresAudioInput: Bool = false
  /// Whether the Camera Session must select an active depth format for this output.
  public let requiresDepthFormat: Bool = true
  /// The underlying AVFoundation output connected to the Camera Session.
  public let output: AVCaptureDepthDataOutput

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
      let orientation = outputOrientation
      queue.async { self.metadataOrientation = orientation }
      guard let connection = output.connection(with: .depthData) else { return }
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
    guard let connection = output.connection(with: .depthData) else { return nil }
    return connection.inputStreamResolution
  }

  /// The stream type used when negotiating this output's target resolution.
  public var streamType: StreamType = .depthVideo
  /// The resolution rule negotiated with the other outputs and the connection's ordered ``Constraint``s.
  public var targetResolution: ResolutionRule {
    return .closest(to: options.targetResolution)
  }

  /// Creates a Camera output with the given options.
  public init(options: DepthOutputOptions = .init()) {
    self.output = AVCaptureDepthDataOutput()
    self.delegate = DepthFrameDelegate()
    self.options = options
    self.queue = DispatchQueue(
      label: "com.margelo.camera.depth",
      qos: .userInteractive,
      attributes: [],
      autoreleaseFrequency: .inherit,
      target: nil)

    // Set up our `delegate`
    output.setDelegate(delegate, callbackQueue: queue)
    // Configure `videoSettings`
    output.alwaysDiscardsLateDepthData = options.discardsLateFrames
    output.isFilteringEnabled = options.isFilteringEnabled
    if #available(iOS 26.0, *), output.isDeferredStartSupported {
      // Deferred start allows the Session to delay this output's startup in favor
      // of preview-related outputs to make preview appear faster.
      output.isDeferredStartEnabled = options.allowsDeferredStart
    }
  }

  /// Applies mirroring and orientation settings to this output's current connection.
  ///
  /// ``CameraSession`` calls this method within its configuration batch. Native output integrations must call it on the owning session's configuration queue.
  public func configure(_ config: OutputConfiguration) {
    queue.async { self.mirrorMode = config.mirrorMode }

    guard let connection = output.connection(with: .depthData) else {
      return
    }
    if options.rotatesBuffers {
      // Pipeline should physically rotate buffers on the `connection`
      try? connection.setOrientation(outputOrientation)
      try? connection.setMirrorMode(config.mirrorMode)
    }
  }

  private func getMediaSampleMetadata(
    at timestamp: CMTime,
    orientation bufferOrientation: CameraOrientation,
    isMirrored isBufferMirrored: Bool
  ) -> MediaSampleMetadata {
    // `isMirrored` is relative; if the buffer is already mirrored & we want mirror, good.
    // If not, we need to counter-mirror.
    var isMirrored: Bool
    switch self.mirrorMode {
    case .auto:
      // We just follow along with what the connection gives us.
      isMirrored = false
    case .on:
      // We enabled mirroring. If the buffer is not mirrored, we need to mirror.
      isMirrored = isBufferMirrored == false
    case .off:
      // We disabled mirroring. If the buffer is mirrored, we need to counter-mirror.
      isMirrored = isBufferMirrored == true
    }
    // `orientation` is relative to the target output orientation.
    let relativeOrientation = bufferOrientation.relativeTo(self.metadataOrientation)

    return MediaSampleMetadata(
      timestamp: timestamp,
      orientation: relativeOrientation,
      isMirrored: isMirrored)
  }

  /// Adds a callback that calls the given `onDepthFrame` function
  /// every time the Camera produces a new ``Depth``.
  ///
  /// Registration and callback delivery are serialized on this output's owning queue. Pass `nil` to remove the callback. This method returns after registration is applied. Move UIKit work to the main actor.
  public func setDepthHandler(_ onDepthFrame: ((Depth) -> Void)?) async {
    await queue.perform {
      if let onDepthFrame {
        self.delegate.onDepthFrame = { [weak self] (depth, timestamp, bufferOrientation, isBufferMirrored) in
          guard let self else { return }
          // Prepare Depth Frame + Metadata
          let metadata = self.getMediaSampleMetadata(
            at: timestamp,
            orientation: bufferOrientation,
            isMirrored: isBufferMirrored)
          let depth = Depth(
            depthData: depth,
            metadata: metadata)
          // Deliver the sample on the output queue.
          onDepthFrame(depth)
        }
      } else {
        self.delegate.onDepthFrame = nil
      }
    }
  }

  /// Adds a callback that gets called when a ``Depth`` has
  /// been dropped.
  /// This often happens if your Depth Frame Callback is taking longer
  /// than a frame interval.
  ///
  /// Registration and callback delivery are serialized on this output's owning queue. Pass `nil` to remove the callback. This method returns after registration is applied. Move UIKit work to the main actor.
  public func setDepthDropHandler(_ onDepthFrameDropped: ((FrameDroppedReason) -> Void)?) async {
    await queue.perform {
      if let onDepthFrameDropped {
        self.delegate.onDepthFrameDropped = { avReason in
          let reason = FrameDroppedReason(reason: avReason)
          onDepthFrameDropped(reason)
        }
      } else {
        self.delegate.onDepthFrameDropped = nil
      }
    }
  }
}
