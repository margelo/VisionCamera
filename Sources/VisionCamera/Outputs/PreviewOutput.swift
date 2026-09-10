///
/// PreviewOutput.swift
/// VisionCamera
/// Copyright © 2025 Marc Rousavy @ Margelo
///

import AVFoundation
import Foundation
import UIKit

/// Represents the ``CameraOutput`` for preview.
///
/// The ``PreviewOutput`` needs to be connected
/// to the ``CameraSession`` as an output, as well
/// as to a ``PreviewView`` as a target.
///
/// ```swift
/// let previewOutput = PreviewOutput()
/// let previewView = PreviewView(output: previewOutput)
/// ```
public final class PreviewOutput: CameraOutput, NativePreviewViewOutput {
  /// The media type of the content being streamed
  /// by this ``CameraOutput``.
  public let mediaType: MediaType = .video
  /// The underlying `AVCaptureVideoPreviewLayer` connected to the Camera Session and displayed by ``PreviewView``.
  public let previewLayer: AVCaptureVideoPreviewLayer
  private let orientationManager = InterfaceOrientationManager()
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
  public var outputOrientation: CameraOrientation {
    get {
      return previewLayer.connection?.orientation ?? .up
    }
    set {
      // Setting orientation on a Preview output does nothing,
      // as its orientation is always driven by the `orientationManager`.
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
    guard let connection = previewLayer.connection else { return nil }
    return connection.inputStreamResolution
  }

  /// The stream type used when negotiating this output's target resolution.
  public var streamType: StreamType = .video
  /// The resolution rule negotiated with the other outputs and the connection's ordered ``Constraint``s.
  public let targetResolution: ResolutionRule

  /// Creates a preview output using the main screen's resolution as its target.
  @MainActor
  public init() {
    let screen = UIScreen.main
    self.targetResolution = .atLeast(CGSize(width: screen.bounds.width * screen.scale, height: screen.bounds.height * screen.scale))
    self.previewLayer = AVCaptureVideoPreviewLayer()
    self.previewLayer.videoGravity = .resizeAspectFill
    self.orientationManager.startUpdates { [weak self] orientation in
      guard let self else { return }
      if let connection = self.previewLayer.connection {
        try? connection.setOrientation(orientation)
      }
    }
  }

  deinit {
    orientationManager.stopUpdates()
  }

  /// Applies mirroring and orientation settings to this output's current connection.
  ///
  /// ``CameraSession`` calls this method within its configuration batch. Native output integrations must call it on the owning session's configuration queue.
  public func configure(_ config: OutputConfiguration) {
    guard let connection = previewLayer.connection else {
      return
    }
    try? connection.setMirrorMode(config.mirrorMode)
    if let interfaceOrientation = orientationManager.currentOrientation {
      try? connection.setOrientation(interfaceOrientation)
    }
  }
}
