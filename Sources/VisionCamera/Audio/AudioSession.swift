//
//  AudioSession.swift
//  VisionCamera
//
//  Created by Marc Rousavy on 07.01.26.
//

import AVFoundation
import Foundation

final class AudioSession {
  let audioSession: AVCaptureSession
  let input: AVCaptureDeviceInput
  let output: AVCaptureAudioDataOutput
  private let queue: DispatchQueue
  private let delegate: AudioFrameDelegate

  init() throws {
    guard AVCaptureDevice.authorizationStatus(for: .audio) == .authorized else {
      throw CameraError(message: "Microphone permission has not been granted.")
    }
    logger.log("Initializing AudioSession...")
    // 1. Create AVCaptureSession
    self.audioSession = AVCaptureSession()
    // 2. Batch the coming changes
    self.audioSession.beginConfiguration()
    let audioSession = self.audioSession
    defer { audioSession.commitConfiguration() }

    // 3. Create audio input
    guard let microphone = AVCaptureDevice.default(for: .audio) else {
      throw CameraError(message: "No microphone available!")
    }
    self.input = try AVCaptureDeviceInput(device: microphone)

    // 4. Add audio input
    guard audioSession.canAddInput(input) else {
      throw CameraError(
        message: "Microphone \(input) cannot be added to AVCaptureSession \(audioSession)!")
    }
    audioSession.addInput(input)

    // 5. Create audio output (AVCaptureAudioDataOutput)
    self.output = AVCaptureAudioDataOutput()
    // 6. Add audio output
    guard audioSession.canAddOutput(output) else {
      throw CameraError(
        message: "Audio output \(output) cannot be added to AVCaptureSession \(audioSession)!")
    }
    audioSession.addOutput(output)

    // 7. Create a DispatchQueue for our callbacks
    self.queue = DispatchQueue(
      label: "com.margelo.camera.audio",
      qos: .utility
    )

    // 8. Add delegate/listener
    self.delegate = AudioFrameDelegate()
    output.setSampleBufferDelegate(delegate, queue: queue)
  }

  func setOnFrameListener(onFrame: @escaping (CMSampleBuffer, CMTime) -> Void) {
    queue.async { self.delegate.onFrame = onFrame }
  }

  func start() {
    queue.async {
      logger.log("Starting AudioSession...")
      self.audioSession.startRunning()
    }
  }

  func stop() {
    queue.async {
      logger.log("Stopping AudioSession...")
      self.audioSession.stopRunning()
    }
  }
}
