// Copyright © 2025 Marc Rousavy @ Margelo

import CoreLocation

/// Video Recorder settings for a ``Recorder``
/// created by a ``VideoOutput``.
///
/// See ``VideoOutput``
/// See ``Recorder``
/// See ``VideoOutput/makeRecorder(settings:)``
public struct RecorderSettings {
  /// Sets the given `CLLocation` to be embedded
  /// into the video metadata using the ISO-6709 standard.
  public var location: CLLocation?
  /// The absolute path (including file name and extension) where
  /// the recording file should be written to, or `nil` to
  /// create a file in the device's temporary directory.
  /// Pass a filesystem path, not a `file://` URL.
  ///
  /// All parent directories in this ``RecorderSettings/filePath`` will
  /// be automatically created if they do not yet exist.
  ///
  /// Defaults to `nil`.
  public var filePath: String?
  /// If set, the recording automatically stops once it reaches
  /// this duration, in seconds.
  ///
  /// When the limit is reached, the recording is finalized
  /// successfully, and the `onRecordingFinished` callback
  /// passed to
  /// ``Recorder/startRecording(onRecordingFinished:onRecordingError:onRecordingPaused:onRecordingResumed:)``
  /// is invoked with the resulting file path, the same
  /// behavior as calling ``Recorder/stopRecording()``.
  ///
  /// Defaults to `nil`.
  public var maxDuration: Double?
  /// If set, the recording automatically stops once the file
  /// reaches this size, in bytes.
  ///
  /// When the limit is reached, the recording is finalized
  /// successfully, and the `onRecordingFinished` callback
  /// passed to
  /// ``Recorder/startRecording(onRecordingFinished:onRecordingError:onRecordingPaused:onRecordingResumed:)``
  /// is invoked with the resulting file path, the same
  /// behavior as calling ``Recorder/stopRecording()``.
  ///
  /// Defaults to `nil`.
  public var maxFileSize: Double?

  /// Creates settings for one recording, including its destination and optional recording limits.
  ///
  /// - Parameters:
  ///   - location: Sets the given `CLLocation` to be embedded into the video metadata using the ISO-6709 standard.
  ///   - filePath: The absolute path (including file name and extension) where the recording file should be written to, or `nil` to create a file in the device's temporary directory. Pass a filesystem path, not a `file://` URL.
  ///   - maxDuration: If set, the recording automatically stops once it reaches this duration, in seconds.
  ///   - maxFileSize: If set, the recording automatically stops once the file reaches this size, in bytes.
  public init(
    location: CLLocation? = nil,
    filePath: String? = nil,
    maxDuration: Double? = nil,
    maxFileSize: Double? = nil
  ) {
    self.location = location
    self.filePath = filePath
    self.maxDuration = maxDuration
    self.maxFileSize = maxFileSize
  }
}
