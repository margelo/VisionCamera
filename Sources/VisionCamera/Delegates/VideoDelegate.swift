// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation
import Foundation

final class VideoDelegate: NSObject, AVCaptureFileOutputRecordingDelegate {
  private let queue: DispatchQueue
  private let onRecordingStarted: () -> Void
  private let onRecordingPaused: (() -> Void)?
  private let onRecordingResumed: (() -> Void)?
  private let onRecordingFinished: (URL, RecordingFinishedReason) -> Void
  private let onRecordingError: (any Error) -> Void
  private var didStart = false
  private var didFinish = false

  init(
    queue: DispatchQueue,
    onRecordingStarted: @escaping () -> Void,
    onRecordingPaused: (() -> Void)?,
    onRecordingResumed: (() -> Void)?,
    onRecordingFinished: @escaping (URL, RecordingFinishedReason) -> Void,
    onRecordingError: @escaping (any Error) -> Void
  ) {
    self.queue = queue
    self.onRecordingStarted = onRecordingStarted
    self.onRecordingPaused = onRecordingPaused
    self.onRecordingResumed = onRecordingResumed
    self.onRecordingFinished = onRecordingFinished
    self.onRecordingError = onRecordingError
    super.init()
  }

  private func recordingDidStart() {
    queue.async {
      guard !self.didStart, !self.didFinish else { return }
      self.didStart = true
      self.onRecordingStarted()
    }
  }

  func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, startPTS: CMTime, from connections: [AVCaptureConnection]) {
    recordingDidStart()
  }

  func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
    recordingDidStart()
  }

  func fileOutput(_ output: AVCaptureFileOutput, didPauseRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
    queue.async { if !self.didFinish { self.onRecordingPaused?() } }
  }

  func fileOutput(_ output: AVCaptureFileOutput, didResumeRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
    queue.async { if !self.didFinish { self.onRecordingResumed?() } }
  }

  func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: (any Error)?) {
    queue.async {
      guard !self.didFinish else { return }
      self.didFinish = true
      if let error {
        let nativeError = error as NSError
        switch nativeError.code {
        case AVError.maximumDurationReached.rawValue where nativeError.domain == AVFoundationErrorDomain:
          self.onRecordingFinished(outputFileURL, .maxDurationReached)
        case AVError.maximumFileSizeReached.rawValue where nativeError.domain == AVFoundationErrorDomain:
          self.onRecordingFinished(outputFileURL, .maxFileSizeReached)
        default:
          self.onRecordingError(error)
        }
      } else {
        self.onRecordingFinished(outputFileURL, .stopped)
      }
    }
  }
}
