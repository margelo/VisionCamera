///
/// CameraPreviewOutput.swift
/// VisionCamera
/// Copyright © 2025 Marc Rousavy @ Margelo
///

import AVFoundation
import Foundation
import UIKit

public final class CameraPreviewOutput: CameraOutput, NativePreviewViewOutput {
  public let mediaType: MediaType = .video
  public let previewLayer: AVCaptureVideoPreviewLayer
  private let orientationManager = InterfaceOrientationManager()
  public var outputOrientation: CameraOrientation {
    get {
      return previewLayer.connection?.orientation ?? .up
    }
    set {
      // Setting orientation on a Preview output does nothing,
      // as its orientation is always driven by the `orientationManager`.
    }
  }
  public var currentResolution: Size? {
    guard let connection = previewLayer.connection else { return nil }
    return connection.inputStreamResolution
  }

  public var streamType: StreamType = .video
  /// The Preview can never display more pixels than the screen has,
  /// so Format at least as large as the screen (`>=`) is a perfect
  /// match - hence `.min`. This is only a _bias_; a slightly smaller
  /// Format only gets a small penalty (it is upscaled on-screen), so
  /// other outputs (e.g. a video recording with an explicit
  /// `targetResolution`) can still win the resolution negotiation.
  ///
  /// We use the screen size instead of the actual view size here
  /// because the view might not even be laid out yet at the time
  /// the resolution negotiation runs.
  public let targetResolution: ResolutionRule

  @MainActor
  public init() {
    let screen = UIScreen.main
    self.targetResolution = .min(Size(width: screen.bounds.width * screen.scale, height: screen.bounds.height * screen.scale))
    self.previewLayer = AVCaptureVideoPreviewLayer()
    self.previewLayer.videoGravity = .resizeAspectFill
    self.orientationManager.startOrientationUpdates { [weak self] orientation in
      guard let self else { return }
      if let connection = self.previewLayer.connection {
        try? connection.setOrientation(orientation)
      }
    }
  }

  deinit {
    orientationManager.stopOrientationUpdates()
  }

  public func configure(config: OutputConfiguration) {
    guard let connection = previewLayer.connection else {
      return
    }
    try? connection.setMirrorMode(config.mirrorMode)
    if let interfaceOrientation = orientationManager.currentOrientation {
      try? connection.setOrientation(interfaceOrientation)
    }
  }
}
