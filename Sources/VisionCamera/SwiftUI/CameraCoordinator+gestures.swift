// Copyright © 2026 Marc Rousavy @ Margelo

extension CameraCoordinator {
  func updateGestures() {
    guard let camera, let preview else { return }
    let enableFocus = camera.options.enableTapToFocusGesture
    let enableZoom = camera.options.enableZoomGesture && camera.options.zoom?.isFixed != true
    var changed = false
    if enableFocus != (focusGesture != nil) {
      focusGesture = enableFocus ? TapToFocusGestureController() : nil
      focusGesture?.controller = controller
      changed = true
    }
    if enableZoom != (zoomGesture != nil) {
      zoomSubscription?.cancel()
      zoomSubscription = nil
      zoomGesture = enableZoom ? ZoomGestureController() : nil
      zoomGesture?.controller = controller
      zoomSubscription = zoomGesture?.observeZoomChanges { [weak self] zoom in
        guard let self, case .binding(let binding) = self.camera?.options.zoom else { return }
        // The gesture already applies the value on the session queue. Avoid writing it a second time.
        self.appliedZoom = zoom
        if binding.wrappedValue != zoom { binding.wrappedValue = zoom }
      }
      changed = true
    }
    if changed {
      var gestures: [any GestureController] = []
      if let focusGesture { gestures.append(focusGesture) }
      if let zoomGesture { gestures.append(zoomGesture) }
      preview.gestureControllers = gestures
    }
  }
}
