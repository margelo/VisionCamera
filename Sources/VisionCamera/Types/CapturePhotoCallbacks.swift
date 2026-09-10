// Copyright © 2025 Marc Rousavy @ Margelo

import UIKit

/// Callbacks for a ``CameraPhotoOutput/capturePhoto(settings:callbacks:)``
/// call.
///
/// See ``CameraPhotoOutput``
///
/// All callbacks run on the photo output's serial queue. Dispatch UIKit updates to the main actor.
public struct CapturePhotoCallbacks {
  /// Called when the pipeline starts
  /// the capture.
  public var onWillBeginCapture: (() -> Void)?
  /// Called just before the pipeline
  /// starts capturing the photo.
  public var onWillCapturePhoto: (() -> Void)?
  /// Called just after the pipeline
  /// captured a photo.
  public var onDidCapturePhoto: (() -> Void)?
  /// Called with a `UIImage` suitable for preview or thumbnail updates when the processed Photo supplies a
  /// preview image.
  ///
  /// This is called only when ``PhotoOutputOptions/previewImageTargetSize`` is set and the captured Photo
  /// contains a preview image.
  public var onPreviewImageAvailable: ((_ previewImage: UIImage) -> Void)?

  /// Creates the callbacks for a photo capture. Unspecified callbacks are not invoked.
  ///
  /// - Parameters:
  ///   - onWillBeginCapture: Called when the pipeline starts the capture.
  ///   - onWillCapturePhoto: Called just before the pipeline starts capturing the photo.
  ///   - onDidCapturePhoto: Called just after the pipeline captured a photo.
  ///   - onPreviewImageAvailable: Called with a `UIImage` suitable for preview or thumbnail updates when the processed Photo supplies a preview image.
  public init(
    onWillBeginCapture: (() -> Void)? = nil,
    onWillCapturePhoto: (() -> Void)? = nil,
    onDidCapturePhoto: (() -> Void)? = nil,
    onPreviewImageAvailable: ((_ previewImage: UIImage) -> Void)? = nil
  ) {
    self.onWillBeginCapture = onWillBeginCapture
    self.onWillCapturePhoto = onWillCapturePhoto
    self.onDidCapturePhoto = onDidCapturePhoto
    self.onPreviewImageAvailable = onPreviewImageAvailable
  }
}
