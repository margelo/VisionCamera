// Copyright © 2025 Marc Rousavy @ Margelo

import CoreLocation
import CoreMedia
import Foundation

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
  /// The file URL (including file name and extension) where
  /// the recording file should be written to, or `nil` to
  /// create a file in the device's temporary directory.
  ///
  /// All parent directories of this ``RecorderSettings/fileURL`` will
  /// be automatically created if they do not yet exist.
  ///
  /// Defaults to `nil`.
  public var fileURL: URL?
  /// If set, the recording automatically stops once it reaches
  /// this duration.
  ///
  /// When the limit is reached, the recording is finalized
  /// successfully, and the `onFinished` callback
  /// passed to
  /// ``Recorder/start(onFinished:onError:onPaused:onResumed:)``
  /// is invoked with the resulting video file, the same
  /// behavior as calling ``Recorder/stop()``.
  ///
  /// Defaults to `nil`.
  public var maxDuration: CMTime?
  /// If set, the recording automatically stops once the file
  /// reaches this size, in bytes.
  ///
  /// When the limit is reached, the recording is finalized
  /// successfully, and the `onFinished` callback
  /// passed to
  /// ``Recorder/start(onFinished:onError:onPaused:onResumed:)``
  /// is invoked with the resulting video file, the same
  /// behavior as calling ``Recorder/stop()``.
  ///
  /// Defaults to `nil`.
  public var maxFileSize: Int64?

  /// Creates settings for one recording, including its destination and optional recording limits.
  ///
  /// - Parameters:
  ///   - location: Sets the given `CLLocation` to be embedded into the video metadata using the ISO-6709 standard.
  ///   - fileURL: The destination file URL, or `nil` to create a file in the device's temporary directory.
  ///   - maxDuration: A positive, finite recording duration limit, or `nil` for no limit.
  ///   - maxFileSize: If set, the recording automatically stops once the file reaches this size, in bytes.
  public init(
    location: CLLocation? = nil,
    fileURL: URL? = nil,
    maxDuration: CMTime? = nil,
    maxFileSize: Int64? = nil
  ) {
    self.location = location
    self.fileURL = fileURL
    self.maxDuration = maxDuration
    self.maxFileSize = maxFileSize
  }
}
