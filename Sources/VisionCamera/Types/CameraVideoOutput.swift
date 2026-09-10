// Copyright © 2025 Marc Rousavy @ Margelo

/// A Video output allows recording videos, possibly with audio, to a file.
///
/// Create an output with ``VisionCamera/createVideoOutput(options:)``, attach it to a session, and create a
/// ``Recorder`` for each recording.
///
/// ```swift
/// let camera = VisionCamera()
/// let videoOutput = camera.createVideoOutput(
///   options: VideoOutputOptions(enableAudio: true))
/// ```
public protocol CameraVideoOutput: CameraOutput {
  /// Gets all supported ``VideoCodec`` values this
  /// ``CameraVideoOutput`` currently can record in.
  ///
  /// This method must be called after the ``CameraVideoOutput``
  /// has been attached to a Camera Session.
  ///
  /// - Throws: This method throws if you call it before this output
  /// is attached to a Camera Session (via ``CameraSession/configure(connections:config:)``).
  func getSupportedVideoCodecs() throws -> [VideoCodec]
  /// Set the output settings for this video output.
  /// This method must be called after the output has been
  /// attached to the Camera Session, and before
  /// ``CameraVideoOutput/createRecorder(settings:)``.
  ///
  /// - Parameter settings: The output settings to apply to subsequent recordings.
  /// - Throws: An error if the requested settings cannot be applied to the connected output.
  func setOutputSettings(settings: VideoOutputSettings) async throws
  /// Creates and prepares a new ``Recorder``
  /// instance with the given ``RecorderSettings``.
  ///
  /// The ``Recorder`` will record to the configured
  /// file path, or to a temporary file if no path was provided.
  /// The ``Recorder``'s file paths are filesystem paths,
  /// not `file://` URLs.
  /// It can only record once.
  ///
  /// If you want to create a second recording,
  /// you must create a new ``Recorder``.
  ///
  /// Connect the output to a session before starting the Recorder.
  /// ``CameraVideoFrameOutput`` requires a connection when creating the Recorder;
  /// ``MovieFileCameraVideoOutput`` checks the connection when recording starts.
  ///
  /// - Parameter settings: The destination, location metadata, and optional recording limits.
  /// - Returns: A prepared Recorder that can be started once.
  /// - Throws: An error if the recording pipeline cannot be prepared.
  func createRecorder(settings: RecorderSettings) async throws -> any Recorder
}
