// Copyright © 2026 Marc Rousavy @ Margelo

@MainActor
struct CameraCallbacks {
  var onConfigured: ((CameraController) -> Void)?
  var onSessionConfigSelected: ((CameraSessionConfig) -> Void)?
  var onStarted: (() -> Void)?
  var onStopped: (() -> Void)?
  var onError: ((any Error) -> Void)?
  var onInterruptionStarted: ((InterruptionReason) -> Void)?
  var onInterruptionEnded: (() -> Void)?
  var onSubjectAreaChanged: (() -> Void)?
  var onPreviewStarted: (() -> Void)?
  var onPreviewStopped: (() -> Void)?
  var onUIRotationChanged: ((Double) -> Void)?
  var onPreviewChanged: ((PreviewView?) -> Void)?
}
