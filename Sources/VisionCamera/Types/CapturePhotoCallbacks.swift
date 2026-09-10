// Copyright © 2025 Marc Rousavy @ Margelo

import UIKit

public struct CapturePhotoCallbacks {
  public var onWillBeginCapture: (() -> Void)?
  public var onWillCapturePhoto: (() -> Void)?
  public var onDidCapturePhoto: (() -> Void)?
  public var onPreviewImageAvailable: ((_ previewImage: UIImage) -> Void)?

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
