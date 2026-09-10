// Copyright © 2026 Marc Rousavy @ Margelo

import AVFoundation

@MainActor
struct CameraViewOptions {
  var configuration: CameraViewConfiguration
  var isActive: Bool
  var resizeMode: PreviewResizeMode = .aspectFill
  var orientationSource: OrientationSource? = .device
  var controllerConfiguration = CameraControllerConfiguration()
  var zoom: CameraZoom?
  var exposureBias: Double?
  var torchMode: AVCaptureDevice.TorchMode = .off
  var initialZoom: Double?
  var initialExposureBias: Double?
  var enableZoomGesture = false
  var enableTapToFocusGesture = false
}
