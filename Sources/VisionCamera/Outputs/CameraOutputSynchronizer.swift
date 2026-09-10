///
/// CameraDepthFrameOutput.swift
/// VisionCamera
/// Copyright © 2025 Marc Rousavy @ Margelo
///

import AVFoundation
import Foundation

/// A ``CameraOutputSynchronizer`` synchronizes 2 or more
/// ``CameraOutput``s to align their timestamps.
///
/// The most common use-case is to synchronize a
/// ``CameraFrameOutput`` and a ``CameraDepthFrameOutput``
/// to ensure the delivered ``Frame`` and ``Depth``
/// are synchronized.
///
/// When an output is connected to the ``CameraOutputSynchronizer``
/// you should no longer use its own frame callback, but instead
/// use the ``CameraOutputSynchronizer/setOnFramesCallback(onFrames:)`` provided here.
public final class CameraOutputSynchronizer {
  private let delegate: SynchronizedOutputDelegate
  private let queue: DispatchQueue
  private let synchronizer: AVCaptureDataOutputSynchronizer

  /// The Camera outputs synchronized by this instance, in their supplied order.
  public let outputs: [any CameraOutput]

  /// Creates a synchronizer for two or more connected Camera outputs.
  ///
  /// - Throws: If fewer than two outputs are given, an output does not conform to ``NativeCameraOutput``, or an output is not connected to a Camera Session.
  public init(outputs: [any CameraOutput]) throws {
    // TODO: Make sure all outputs are running on the same DispatchQueue!!
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
      return nativeOutput.output
    }
    guard avOutputs.count >= 2 else {
      throw CameraError(
        message: "Cannot create CameraOutputSynchronizer with less than 2 outputs!")
    }
    let allConnected = avOutputs.allSatisfy { !$0.connections.isEmpty }
    guard allConnected else {
      throw CameraError(
        message:
          "Cannot create CameraOutputSynchronizer when not all of the given outputs are connected to the Camera!"
      )
    }
    self.synchronizer = AVCaptureDataOutputSynchronizer(dataOutputs: avOutputs)
    self.delegate = SynchronizedOutputDelegate()

    // Set delegate
    self.synchronizer.setDelegate(self.delegate, queue: self.queue)
  }

  ///
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

  /// Sets the callback that gets called when a ``Frame`` or
  /// ``Depth``-frame has been dropped, possibly due to a long
  /// drift in timelines.
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
