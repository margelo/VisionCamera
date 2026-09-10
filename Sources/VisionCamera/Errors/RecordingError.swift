// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation
import Foundation

/// A configuration or lifecycle failure in a video recording.
///
/// AVFoundation and file-system errors pass through unchanged when the native operation supplies an error.
public enum RecordingError: Error, LocalizedError {
  /// The video output is not connected to a Camera session.
  case outputNotConnected
  /// The video output has no connected input port.
  case inputNotConnected
  /// The connected Camera input does not supply a master clock.
  case masterClockUnavailable
  /// The requested codec is unavailable on this output or OS version.
  case unsupportedCodec(AVVideoCodecType)
  /// The requested codec does not support a custom bit rate.
  case bitRateUnsupported(AVVideoCodecType)
  /// AVFoundation cannot recommend encoding settings for the connected video output.
  case videoSettingsUnavailable
  /// The asset writer cannot apply the supplied settings to this media type.
  case invalidOutputSettings(mediaType: AVMediaType)
  /// A track of this media type was already initialized.
  case trackAlreadyConfigured(mediaType: AVMediaType)
  /// A sample arrived for a media type that has no initialized track.
  case trackUnavailable(mediaType: AVMediaType)
  /// A recording destination must be a file URL.
  case invalidDestination(URL)
  /// A recording duration limit must be a positive, finite time.
  case invalidDurationLimit(CMTime)
  /// A recording file-size limit must be a positive byte count.
  case invalidFileSizeLimit(Int64)
  /// A single-use recorder has already been started.
  case alreadyStarted
  /// The output already has an active recording.
  case recordingInProgress
  /// The requested operation needs an active recording.
  case notRecording
  /// AVFoundation finished the recording before confirming that it started.
  case finishedBeforeStarting
  /// Pausing a movie-file recording requires iOS 18 or later.
  case pauseRequiresIOS18
  /// Resuming a movie-file recording requires iOS 18 or later.
  case resumeRequiresIOS18
  /// The asset writer failed to start without supplying an underlying error.
  case writerCouldNotStart
  /// The asset writer failed to append a sample without supplying an underlying error.
  case writerCouldNotAppend
  /// The asset writer is no longer writing.
  case writerNotWriting
  /// The asset writer failed to finalize the file without supplying an underlying error.
  case writerCouldNotFinish
  /// The recording cannot finish before receiving its first video frame.
  case noVideoFrames

  /// The selected video codec is unavailable for movie metadata.
  case metadataCodecUnavailable
  /// ProRes RAW recording requires locked white balance before preparing the recorder.
  case rawRequiresLockedWhiteBalance
  /// This movie output does not support a custom bit rate.
  case customBitRateUnsupported
  /// The target video bit rate must be positive.
  case invalidBitRate
  /// ProRes codecs control their own bit rate. Choose a ProRes variant instead.
  case proResBitRateUnsupported

  /// A description of the recording failure suitable for display to the user.
  public var errorDescription: String? {
    switch self {
    case .metadataCodecUnavailable:
      return "The selected video codec is unavailable for movie metadata."
    case .rawRequiresLockedWhiteBalance:
      return "ProRes RAW recording requires locked white balance before preparing the recorder."
    case .customBitRateUnsupported:
      return "This movie output does not support a custom bit rate."
    case .invalidBitRate:
      return "The target video bit rate must be positive."
    case .proResBitRateUnsupported:
      return "ProRes codecs control their own bit rate. Choose a ProRes variant instead."

    case .outputNotConnected:
      return "The video output is not connected to a Camera session."
    case .inputNotConnected:
      return "The video output is not connected to a Camera input."
    case .masterClockUnavailable:
      return "The connected Camera input does not have a master clock."
    case .unsupportedCodec(let codec):
      return "The video codec \(codec) is not supported."
    case .bitRateUnsupported(let codec):
      return "The video codec \(codec) does not support a custom bit rate."
    case .videoSettingsUnavailable:
      return "No video encoding settings are available for the connected output."
    case .invalidOutputSettings(let mediaType):
      return "The output settings are not supported for \(mediaType.rawValue)."
    case .trackAlreadyConfigured(let mediaType):
      return "The \(mediaType.rawValue) track has already been initialized."
    case .trackUnavailable(let mediaType):
      return "No \(mediaType.rawValue) track has been initialized."
    case .invalidDestination(let url):
      return "A recording destination must be a file URL. Received \(url)."
    case .invalidDurationLimit(let duration):
      return "The recording duration limit must be a positive, finite time. Received \(duration.seconds) seconds."
    case .invalidFileSizeLimit(let count):
      return "The recording file-size limit must be positive. Received \(count) bytes."
    case .alreadyStarted:
      return "A recorder can only be started once."
    case .recordingInProgress:
      return "A recording is already in progress on this output."
    case .notRecording:
      return "There is no active recording."
    case .finishedBeforeStarting:
      return "Recording finished before it started."
    case .pauseRequiresIOS18:
      return "Pausing a movie-file recording requires iOS 18 or later."
    case .resumeRequiresIOS18:
      return "Resuming a movie-file recording requires iOS 18 or later."
    case .writerCouldNotStart:
      return "The asset writer could not start recording."
    case .writerCouldNotAppend:
      return "The asset writer could not write a media sample."
    case .writerNotWriting:
      return "The asset writer is not writing."
    case .writerCouldNotFinish:
      return "The asset writer could not finalize the recording."
    case .noVideoFrames:
      return "The recording cannot finish before its first video frame."
    }
  }
}
