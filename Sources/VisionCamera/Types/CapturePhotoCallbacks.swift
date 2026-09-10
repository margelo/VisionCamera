// Copyright © 2025 Marc Rousavy @ Margelo

import UIKit

/// Callbacks for a ``PhotoOutput/capturePhoto(settings:callbacks:)``
/// call.
///
/// See ``PhotoOutput``
///
/// All callbacks run on the photo output's serial queue. Dispatch UIKit updates to the main actor.
public struct CapturePhotoCallbacks {
  /// Called when the pipeline starts
  /// the capture.
  public var willBeginCapture: (() -> Void)?
  /// Called just before the pipeline
  /// starts capturing the photo.
  public var willCapturePhoto: (() -> Void)?
  /// Called just after the pipeline
  /// captured a photo.
  public var didCapturePhoto: (() -> Void)?
  /// Called with a `UIImage` suitable for preview or thumbnail updates when the processed Photo supplies a
  /// preview image.
  ///
  /// This is called only when ``PhotoOutputOptions/previewImageTargetSize`` is set and the captured Photo
  /// contains a preview image.
  public var didReceivePreviewImage: ((_ previewImage: UIImage) -> Void)?

  /// Creates the callbacks for a photo capture. Unspecified callbacks are not invoked.
  ///
  /// - Parameters:
  ///   - willBeginCapture: Called when the pipeline starts the capture.
  ///   - willCapturePhoto: Called just before the pipeline starts capturing the photo.
  ///   - didCapturePhoto: Called just after the pipeline captured a photo.
  ///   - didReceivePreviewImage: Called with a `UIImage` suitable for preview or thumbnail updates when the processed Photo supplies a preview image.
  public init(
    willBeginCapture: (() -> Void)? = nil,
    willCapturePhoto: (() -> Void)? = nil,
    didCapturePhoto: (() -> Void)? = nil,
    didReceivePreviewImage: ((_ previewImage: UIImage) -> Void)? = nil
  ) {
    self.willBeginCapture = willBeginCapture
    self.willCapturePhoto = willCapturePhoto
    self.didCapturePhoto = didCapturePhoto
    self.didReceivePreviewImage = didReceivePreviewImage
  }
}
