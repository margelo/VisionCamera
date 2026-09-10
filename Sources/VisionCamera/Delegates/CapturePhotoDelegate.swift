// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation
import Foundation

final class CapturePhotoDelegate: NSObject, AVCapturePhotoCaptureDelegate {
  private let queue: DispatchQueue
  private let onCaptured: (AVCapturePhoto, MediaSampleMetadata) -> Void
  private let onError: (any Error) -> Void
  private let onFinished: () -> Void
  private let callbacks: CapturePhotoCallbacks
  private var didResolve = false
  private var didFinish = false

  init(
    queue: DispatchQueue,
    onCaptured: @escaping (AVCapturePhoto, MediaSampleMetadata) -> Void,
    onError: @escaping (any Error) -> Void,
    onFinished: @escaping () -> Void,
    callbacks: CapturePhotoCallbacks
  ) {
    self.queue = queue
    self.onCaptured = onCaptured
    self.onError = onError
    self.onFinished = onFinished
    self.callbacks = callbacks
    super.init()
  }

  func photoOutput(_ output: AVCapturePhotoOutput, willBeginCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
    queue.async { self.callbacks.onWillBeginCapture?() }
  }

  func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
    queue.async { self.callbacks.onWillCapturePhoto?() }
  }

  func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: (any Error)?) {
    queue.async {
      guard !self.didResolve else { return }
      self.didResolve = true
      do {
        if let error { throw error }
        self.onCaptured(photo, try photo.getMediaSampleMetadata())
      } catch {
        self.onError(error)
      }
    }
  }

  func photoOutput(_ output: AVCapturePhotoOutput, didCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
    queue.async { self.callbacks.onDidCapturePhoto?() }
  }

  func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: (any Error)?) {
    finishCapture(error: error)
  }

  func finishCapture(error: (any Error)?) {
    queue.async {
      guard !self.didFinish else { return }
      self.didFinish = true
      if !self.didResolve {
        self.didResolve = true
        self.onError(error ?? CameraError(message: "Photo capture finished without a photo."))
      }
      self.onFinished()
    }
  }
}
