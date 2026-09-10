// Copyright © 2025 Marc Rousavy @ Margelo

import Foundation

/// A configuration or delivery failure while capturing photos or synchronized samples.
///
/// AVFoundation and file-system errors pass through unchanged when the native operation supplies an error.
public enum CaptureError: Error, LocalizedError {
  /// The output must be connected to a Camera session before capturing.
  case outputNotConnected
  /// AVFoundation finished the capture without delivering a processed photo.
  case missingPhoto
  /// AVFoundation did not prepare the requested capture settings.
  case settingsPreparationCancelled
  /// Photo compression quality must be between `0` and `1`.
  case invalidQuality(Double)
  /// The connected output does not support RAW photo capture.
  case rawCaptureUnsupported
  /// Depth data cannot be embedded in a RAW photo.
  case depthDataUnavailableForRawPhoto
  /// The connected photo output does not support depth data delivery.
  case depthDataUnsupported
  /// The connected photo output does not support camera calibration data delivery.
  case cameraCalibrationDataUnsupported
  /// A synchronizer needs at least two outputs.
  case insufficientSynchronizedOutputs(count: Int)
  /// The output at the supplied index does not provide an AVFoundation data output.
  case unsupportedSynchronizedOutput(index: Int)
  /// The output at the supplied index is not connected to a Camera session.
  case synchronizedOutputNotConnected(index: Int)

  /// A description of the capture failure suitable for display to the user.
  public var errorDescription: String? {
    switch self {
    case .outputNotConnected:
      return "The capture output is not connected to a Camera session."
    case .missingPhoto:
      return "Photo capture finished without a photo."
    case .settingsPreparationCancelled:
      return "Photo settings preparation was cancelled."
    case .invalidQuality(let quality):
      return "Photo quality must be between 0 and 1. Received \(quality)."
    case .rawCaptureUnsupported:
      return "The photo output does not support RAW capture with the selected Camera format."
    case .depthDataUnavailableForRawPhoto:
      return "Depth data is available only in processed photos such as JPEG or HEIC."
    case .depthDataUnsupported:
      return "The photo output does not support depth data delivery."
    case .cameraCalibrationDataUnsupported:
      return "The photo output does not support camera calibration data delivery."
    case .insufficientSynchronizedOutputs(let count):
      return "A synchronizer needs at least two outputs. Received \(count)."
    case .unsupportedSynchronizedOutput(let index):
      return "The output at index \(index) does not provide an AVFoundation data output."
    case .synchronizedOutputNotConnected(let index):
      return "The synchronized output at index \(index) is not connected to a Camera session."
    }
  }
}
