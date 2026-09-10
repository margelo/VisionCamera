// Copyright © 2026 Marc Rousavy @ Margelo

import AVFoundation
import SwiftUI

extension Camera {
  /// Sets how the preview fits the view. The default is ``PreviewResizeMode/aspectFill``.
  public func resizeMode(_ mode: PreviewResizeMode) -> Camera {
    var camera = self
    camera.options.resizeMode = mode
    return camera
  }

  /// Sets mirroring for the preview and all supplied outputs. The default is ``MirrorMode/auto``.
  public func mirrorMode(_ mode: MirrorMode) -> Camera {
    var camera = self
    camera.options.configuration.mirrorMode = mode
    return camera
  }

  /// Selects automatic output orientation. The default is ``OrientationSource/device``.
  ///
  /// Pass `nil` to manage output orientation yourself. The preview always follows its window scene.
  /// In custom mode the Camera does not emit UI rotation events because outputs can have different orientations.
  public func orientationSource(_ source: OrientationSource?) -> Camera {
    var camera = self
    camera.options.orientationSource = source
    return camera
  }

  /// Applies session-wide audio playback options without replacing the session.
  public func sessionConfiguration(_ configuration: CameraSessionConfiguration) -> Camera {
    var camera = self
    camera.options.configuration.sessionConfiguration = configuration
    return camera
  }

  /// Applies low-light boost, smooth autofocus, and distortion correction without renegotiating the session.
  public func controllerConfiguration(_ configuration: CameraControllerConfiguration) -> Camera {
    var camera = self
    camera.options.controllerConfiguration = configuration
    return camera
  }

  /// Sets the zoom factor declaratively without reconfiguring the session.
  ///
  /// A fixed zoom value cannot be combined with ``Camera/enableZoomGesture(_:)``.
  /// Use `zoom(_:)` with a binding to receive native pinch updates.
  public func zoom(_ zoom: Double) -> Camera {
    var camera = self
    camera.options.zoom = .value(zoom)
    return camera
  }

  /// Connects the zoom factor to app state and writes native pinch changes back to that binding.
  ///
  /// Gesture updates stay native unless this binding is supplied. Changes to the binding never
  /// reconfigure the session.
  public func zoom(_ zoom: Binding<Double>) -> Camera {
    var camera = self
    camera.options.zoom = .binding(zoom)
    return camera
  }

  /// Sets exposure compensation in EV without reconfiguring the session.
  public func exposureBias(_ exposure: Double) -> Camera {
    var camera = self
    camera.options.exposureBias = exposure
    return camera
  }

  /// Sets the requested torch mode while the Camera is active. The default is `.off`.
  ///
  /// The torch is turned off before the Camera stops or changes device, and the requested mode is
  /// restored after capture starts again.
  public func torchMode(_ mode: AVCaptureDevice.TorchMode) -> Camera {
    var camera = self
    camera.options.torchMode = mode
    return camera
  }

  /// Sets the initial zoom when attaching a new input device, unless a declarative zoom is supplied.
  ///
  /// Later changes to this initial value do not reset zoom. Use `zoom(_:)` for live updates.
  public func initialZoom(_ zoom: Double?) -> Camera {
    var camera = self
    camera.options.initialZoom = zoom
    return camera
  }

  /// Sets initial exposure compensation when attaching a new input device.
  ///
  /// A declarative ``Camera/exposureBias(_:)`` takes precedence. Later changes to this initial value
  /// do not reset exposure.
  public func initialExposureBias(_ exposure: Double?) -> Camera {
    var camera = self
    camera.options.initialExposureBias = exposure
    return camera
  }

  /// Enables native pinch-to-zoom. Disabled by default.
  ///
  /// Combine this with a zoom binding to synchronize app controls, or omit declarative zoom to keep
  /// all gesture updates native. A fixed zoom and enabled pinch gesture report a configuration error
  /// and keep capture stopped until the conflict is removed.
  public func enableZoomGesture(_ enabled: Bool = true) -> Camera {
    var camera = self
    camera.options.enableZoomGesture = enabled
    return camera
  }

  /// Enables native tap-to-focus using the preview's coordinate conversion. Disabled by default.
  public func enableTapToFocusGesture(_ enabled: Bool = true) -> Camera {
    var camera = self
    camera.options.enableTapToFocusGesture = enabled
    return camera
  }
}
