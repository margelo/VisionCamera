///
/// CameraDepthFrameOutput.swift
/// VisionCamera
/// Copyright © 2025 Marc Rousavy @ Margelo
///

import AVFoundation
import Foundation

public final class CameraDepthFrameOutput: CameraOutput, NativeCameraOutput {
  private let delegate: DepthFrameDelegate
  private let queue: DispatchQueue
  private let options: DepthFrameOutputOptions
  private var mirrorMode: MirrorMode = .auto
  private var metadataOrientation: CameraOrientation = .up
  public let mediaType: MediaType = .depth
  public let requiresAudioInput: Bool = false
  public let requiresDepthFormat: Bool = true
  public let output: AVCaptureDepthDataOutput

  public var outputOrientation: CameraOrientation = .up {
    didSet {
      let orientation = outputOrientation
      queue.async { self.metadataOrientation = orientation }
      guard let connection = output.connection(with: .depthData) else { return }
      if options.enablePhysicalBufferRotation {
        // TODO: Should we apply that within the CameraSession's DispatchQueue? Batch it?
        try? connection.setOrientation(outputOrientation)
      }
    }
  }
  public var currentResolution: Size? {
    guard let connection = output.connection(with: .depthData) else { return nil }
    return connection.inputStreamResolution
  }

  public var streamType: StreamType = .depthVideo
  public var targetResolution: ResolutionRule {
    return .closestTo(options.targetResolution)
  }

  public init(options: DepthFrameOutputOptions) {
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
    output.alwaysDiscardsLateDepthData = options.dropFramesWhileBusy
    output.isFilteringEnabled = options.enableFiltering
    if #available(iOS 26.0, *), output.isDeferredStartSupported {
      // Deferred start allows the Session to delay this output's startup in favor
      // of preview-related outputs to make preview appear faster.
      output.isDeferredStartEnabled = options.allowDeferredStart
    }
  }

  public func configure(config: OutputConfiguration) {
    queue.async { self.mirrorMode = config.mirrorMode }

    guard let connection = output.connection(with: .depthData) else {
      return
    }
    if options.enablePhysicalBufferRotation {
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

  public func setOnDepthFrameCallback(onDepthFrame: ((Depth) -> Void)?) async throws {
    try await queue.perform {
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

  public func setOnDepthFrameDroppedCallback(onDepthFrameDropped: ((FrameDroppedReason) -> Void)?) async throws {
    try await queue.perform {
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
