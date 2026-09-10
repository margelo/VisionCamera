///
/// NativeCameraOutput.swift
/// VisionCamera
/// Copyright © 2025 Marc Rousavy @ Margelo
///

import AVFoundation
import Foundation

// TODO: Try to figure out if we can get the Preview Output conform to the `NativeCameraOutput` protocol too somehow.
//       We have a lot of conditional code that checks `NativeCameraOutput` first, `NativePreviewViewOutput` second.
//       It's possible that I have missed some of those cases because it's only visible at runtime, so let's try to
//       avoid that and get the Preview into here too - maybe the `Output` class could be PreviewLayer then somehow? Idk.

// TODO: Refactor this to expose "requiredMediaTypes" ([.video, .audio, .depth]),
//       so that the +addConnection/+addAudioInput code connects all required outputs.
//       E.g. a AVCapturePhotoOutput might use [.video] or [.video, .depth] (portrait)
//       E.g. a AVCaptureMovieFileOutput might use [.video], [.video, .audio] or [.video, .audio, .depth] (cinematic)
//       Then we can remove `requiresAudioInput` and remove the special handling for adding/removing a
//       microphone connection in our CameraSession. We just add all connections necessary.

// TODO: Not every output should require conformace to `ResolutionNegotiationParticipant`, should it? e.g. metadata/output.

/// The native extension point for Camera outputs backed by `AVCaptureOutput`.
///
/// A custom output also conforms to ``CameraOutput``. ``CameraSession`` connects its native output to the selected input and negotiates its ``ResolutionNegotiationParticipant`` requirements.
public protocol NativeCameraOutput: AnyObject, ResolutionNegotiationParticipant {
  /// The concrete AVFoundation output type used by this Camera output.
  associatedtype Output: AVCaptureOutput

  /// Represents the actual `AVCaptureOutput` that should be added to the `AVCaptureSession`.
  ///
  /// It will be manually connected to the selected input in ``CameraSession/configure(connections:config:)``.
  var output: Output { get }
  /// Whether this native output requires an audio input attached to its `AVCaptureOutput`.
  ///
  /// If `true`, both the Camera input and an audio input will be connected to the output.
  var requiresAudioInput: Bool { get }

  /// Whether this native output requires a depth format to be enabled via `AVCaptureDevice.activeDepthFormat`.
  var requiresDepthFormat: Bool { get }

  /// Called whenever the output configuration might change, in a `beginConfiguration()`/`commitConfiguration()` batch.
  ///
  /// The native output is expected to apply orientation and mirroring settings here. ``CameraSession`` calls this method on its serial configuration queue.
  func configure(config: OutputConfiguration)
}
