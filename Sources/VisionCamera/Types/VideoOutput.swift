// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation

/// A Video output allows recording videos, possibly with audio, to a file.
///
/// Create a ``MovieFileVideoOutput`` or ``VideoFrameOutput``, attach it to a session,
/// and prepare a ``Recorder`` for each recording with ``makeRecorder(settings:)``.
///
/// ```swift
/// let videoOutput = MovieFileVideoOutput(
///   options: VideoOutputOptions(isAudioEnabled: true))
/// ```
public protocol VideoOutput: CameraOutput {
  /// The requested orientation for recorded video, applied to the native connection or recording transform.
  var outputOrientation: CameraOrientation { get set }

  /// The concrete recorder prepared by this output.
  associatedtype Recording: Recorder

  /// Gets all supported `AVVideoCodecType` values this
  /// ``VideoOutput`` currently can record in.
  ///
  /// This query runs on the output's serial queue and must be called after the ``VideoOutput``
  /// has been attached to a Camera Session.
  ///
  /// - Throws: This method throws if you call it before this output
  /// is attached to a Camera Session (via ``CameraSession/configure(_:configuration:)``).
  func supportedVideoCodecs() async throws -> [AVVideoCodecType]
  /// Selects the native video codec for subsequent recordings.
  /// This method must be called after the output has been
  /// attached to the Camera Session, and before
  /// ``VideoOutput/makeRecorder(settings:)``.
  ///
  /// - Parameter codec: A codec returned by ``supportedVideoCodecs()``.
  /// - Throws: An error if the requested settings cannot be applied to the connected output.
  func setVideoCodec(_ codec: AVVideoCodecType) async throws
  /// Creates and prepares a new ``Recorder``
  /// instance with the given ``RecorderSettings``.
  ///
  /// The ``Recorder`` will record to the configured
  /// file URL, or to a temporary file if no URL was provided.
  /// It can only record once.
  ///
  /// If you want to create a second recording,
  /// you must create a new ``Recorder``.
  ///
  /// Connect the output to a session before creating the Recorder.
  ///
  /// - Parameter settings: The destination, location metadata, and optional recording limits.
  /// - Returns: A prepared Recorder that can be started once.
  /// - Throws: An error if the recording pipeline cannot be prepared.
  func makeRecorder(settings: RecorderSettings) async throws -> Recording
}
