///
/// CameraDepthFrameOutput.swift
/// VisionCamera
/// Copyright © 2025 Marc Rousavy @ Margelo
///

import AVFoundation
import Foundation

public final class CameraOutputSynchronizer {
  private let delegate: SynchronizedOutputDelegate
  private let queue: DispatchQueue
  private let synchronizer: AVCaptureDataOutputSynchronizer

  public let outputs: [any CameraOutput]

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
