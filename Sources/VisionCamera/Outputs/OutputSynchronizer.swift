///
/// DepthOutput.swift
/// VisionCamera
/// Copyright © 2025 Marc Rousavy @ Margelo
///

import AVFoundation
import Foundation

/// An ``OutputSynchronizer`` synchronizes one or more
/// ``CameraOutput``s to align their timestamps.
///
/// The most common use-case is to synchronize a
/// ``FrameOutput`` and a ``DepthOutput``
/// to ensure the delivered ``Frame`` and ``Depth``
/// are synchronized.
///
/// When an output is connected to the ``OutputSynchronizer``
/// you should no longer use its own frame callback, but instead
/// use the ``OutputSynchronizer/setOnFramesCallback(onFrames:)`` provided here.
/// Releasing the synchronizer restores each output's original delegate.
public final class OutputSynchronizer {
  private let delegate: SynchronizedOutputDelegate
  private let queue: DispatchQueue
  private let synchronizer: AVCaptureDataOutputSynchronizer

  /// The Camera outputs synchronized by this instance, in their supplied order.
  ///
  /// A ``VideoFrameOutput`` uses its native sample delegate for recording. Synchronizing that output
  /// transfers sample delivery to this synchronizer, so it cannot feed its recorder at the same time.
  public let outputs: [any CameraOutput]

  /// Creates a synchronizer for one or more connected Camera data outputs.
  ///
  /// The first output determines callback timing. Video data, depth data, metadata, and native audio data outputs are supported.
  ///
  /// - Throws: If no data outputs are given, an output is duplicated, an output is unsupported, or an output is not connected to a Camera Session.
  public init(outputs: [any CameraOutput]) throws {
    self.queue = DispatchQueue(
      label: "com.margelo.camera.synchronizer",
      qos: .userInteractive,
      attributes: [],
      autoreleaseFrequency: .inherit,
      target: nil)
    self.outputs = outputs
    let avOutputs = try outputs.map { output in
      guard let nativeOutput = output as? any NativeCameraOutput else {
        throw CameraError(
          message: "Output \(output) is not of type `NativeCameraOutput`!")
      }
      let dataOutput = nativeOutput.output
      guard
        dataOutput is AVCaptureVideoDataOutput || dataOutput is AVCaptureDepthDataOutput
          || dataOutput is AVCaptureMetadataOutput || dataOutput is AVCaptureAudioDataOutput
      else {
        throw CameraError(message: "OutputSynchronizer requires video data, depth data, metadata, or audio data outputs.")
      }
      return dataOutput
    }
    guard !avOutputs.isEmpty else {
      throw CameraError(
        message: "Cannot create OutputSynchronizer without any outputs!")
    }
    guard Set(avOutputs.map(ObjectIdentifier.init)).count == avOutputs.count else {
      throw CameraError(message: "OutputSynchronizer requires distinct native outputs.")
    }
    let allConnected = avOutputs.allSatisfy { !$0.connections.isEmpty }
    guard allConnected else {
      throw CameraError(
        message:
          "Cannot create OutputSynchronizer when not all of the given outputs are connected to the Camera!"
      )
    }
    self.synchronizer = AVCaptureDataOutputSynchronizer(dataOutputs: avOutputs)
    self.delegate = SynchronizedOutputDelegate(outputs: outputs)

    // Set delegate
    self.synchronizer.setDelegate(self.delegate, queue: self.queue)
  }

  deinit {
    // AVFoundation restores each output's original delegate when the synchronizer releases delivery.
    synchronizer.setDelegate(nil, queue: nil)
  }

  /// Sets the callback for synchronized video, depth, metadata, and audio samples.
  ///
  /// Registration and callback delivery are serialized on this synchronizer's owning queue. Pass `nil` to remove the callback. This method returns after registration is applied. Move UIKit work to the main actor.
  public func setOnFramesCallback(
    onFrames: (([SynchronizedFrame]) -> Void)?
  ) async {
    await queue.perform {
      if let onFrames {
        self.delegate.onFrames = { frames in
          let samples = frames.map { $0.toSynchronizedFrame() }
          onFrames(samples)
        }
      } else {
        self.delegate.onFrames = nil
      }
    }
  }

  /// Sets the callback for dropped video, depth, or audio samples.
  ///
  /// Audio drops use ``MediaType/other(_:)`` with AVFoundation's audio media type.
  ///
  /// Registration and callback delivery are serialized on this synchronizer's owning queue. Pass `nil` to remove the callback. This method returns after registration is applied. Move UIKit work to the main actor.
  public func setOnFrameDroppedCallback(onFrameDropped: ((MediaType, FrameDroppedReason) -> Void)?) async {
    await queue.perform {
      if let onFrameDropped {
        self.delegate.onFrameDropped = { mediaType, avReason in
          let reason = FrameDroppedReason(reason: avReason)
          onFrameDropped(mediaType, reason)
        }
      } else {
        self.delegate.onFrameDropped = nil
      }
    }
  }
}
