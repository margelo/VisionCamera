// Copyright © 2026 Marc Rousavy @ Margelo

@MainActor
struct CameraViewOptions {
  var configuration: CameraViewConfiguration
  var isActive: Bool
  var resizeMode: PreviewResizeMode = .cover
  var orientationSource: OrientationSource? = .device
  var controllerConfiguration = CameraControllerConfiguration()
  var zoom: CameraZoom?
  var exposureBias: Double?
  var torchMode: TorchMode = .off
  var initialZoom: Double?
  var initialExposureBias: Double?
  var enableZoomGesture = false
  var enableTapToFocusGesture = false
}
