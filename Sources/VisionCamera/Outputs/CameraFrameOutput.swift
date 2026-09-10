///
/// CameraFrameOutput.swift
/// VisionCamera
/// Copyright © 2025 Marc Rousavy @ Margelo
///

import AVFoundation
import Foundation

public final class CameraFrameOutput: CameraOutput, NativeCameraOutput {
  private let delegate: FrameDelegate
  private let queue: DispatchQueue
  private var mirrorMode: MirrorMode = .auto
  private var metadataOrientation: CameraOrientation = .up
  private let options: FrameOutputOptions
  public let mediaType: MediaType = .video
  public let requiresAudioInput: Bool = false
  public let requiresDepthFormat: Bool = false
  public let output: AVCaptureVideoDataOutput
  public var outputOrientation: CameraOrientation = .up {
    didSet {
      let orientation = outputOrientation
      queue.async { self.metadataOrientation = orientation }
      guard let connection = output.connection(with: .video) else { return }
      if options.enablePhysicalBufferRotation {
        // TODO: Should we apply that within the CameraSession's DispatchQueue? Batch it?
        try? connection.setOrientation(outputOrientation)
      }
    }
  }
  public var currentResolution: Size? {
    guard let connection = output.connection(with: .video) else { return nil }
    return connection.inputStreamResolution
  }

  public var streamType: StreamType = .video
  public var targetResolution: ResolutionRule {
    return .closestTo(options.targetResolution)
  }

  public init(options: FrameOutputOptions) {
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
    output.videoSettings = videoSettingsForPixelFormat(options.pixelFormat)
    // If the pipeline stalls, drop frames to avoid blowing up RAM
    output.alwaysDiscardsLateVideoFrames = options.dropFramesWhileBusy
    // The session configures the video resolution, we don't want to downscale here by default.
    output.automaticallyConfiguresOutputBufferDimensions = false
    if #available(iOS 26.0, *), output.isDeferredStartSupported {
      // Deferred start allows the Session to delay this output's startup in favor
      // of preview-related outputs to make preview appear faster.
      output.isDeferredStartEnabled = options.allowDeferredStart
    }
    // TODO: Add a flag called `allowBufferResizing` and probably get rid of `enablePreviewSizedOutputBuffers`
    //       If `allowBufferResizing` is true, we can set `.videoSettings`/dimensions here to `options.targetResolution`
    //       and `targetResolution` to `.any` (to not participate in resolution negotiations).
    //       If `allowBufferResizing` is false, we don't set `.videoSettings` ("native" resolution), and reflect our
    //       target resolution via `targetResolution` to participate in resolution negotiations.
    if #available(iOS 17.0, *), options.enablePreviewSizedOutputBuffers {
      output.deliversPreviewSizedOutputBuffers = true
    }
    if #available(iOS 26.0, *) {
      // We don't need HDR metadata, as that's only useful for encoders.
      output.preservesDynamicHDRMetadata = false
    }
  }

  public func configure(config: OutputConfiguration) {
    queue.async { self.mirrorMode = config.mirrorMode }

    guard let connection = output.connection(with: .video) else {
      return
    }
    if options.enablePhysicalBufferRotation {
      // Pipeline should physically rotate buffers on the `connection`
      try? connection.setOrientation(outputOrientation)
      try? connection.setMirrorMode(config.mirrorMode)
    }
    if options.enableCameraMatrixDelivery {
      // Pipeline should deliver camera matrix (via attachment on `CMSampleBuffer`)
      if connection.isCameraIntrinsicMatrixDeliverySupported {
        connection.isCameraIntrinsicMatrixDeliveryEnabled = true
      }
    }
  }

  private func videoSettingsForPixelFormat(_ targetPixelFormat: TargetVideoPixelFormat) -> [String:
    Any]
  {
    let pixelFormat = targetPixelFormat.toCVPixelFormatType()
    switch pixelFormat {
    case .native:
      // Empty dictionary means "choose device-native format" (most efficient)
      return [:]
    case .specific(let format):
      // Use a specific format (e.g. 32 BGRA)
      return [
        kCVPixelBufferPixelFormatTypeKey as String: format
      ]
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

  public func setOnFrameCallback(onFrame: ((Frame) -> Void)?) async {
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
            buffer: sampleBuffer,
            metadata: metadata)
          // Deliver the sample on the output queue.
          onFrame(frame)
        }
      } else {
        self.delegate.onFrame = nil
      }
    }
  }

  public func setOnFrameDroppedCallback(onFrameDropped: ((FrameDroppedReason) -> Void)?) async {
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
