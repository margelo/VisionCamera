// Copyright © 2026 Marc Rousavy @ Margelo

extension Camera {
  /// Receives the controller after a successful current session configuration.
  ///
  /// Runs on the main actor before capture starts, after attempting initial control updates.
  /// A failed control update is reported through ``Camera/onError(_:)`` and does not undo the configured session.
  /// Replace any previously stored controller.
  /// Output capabilities and recording preparation are available here. A stale configuration that
  /// finishes after the device or outputs change does not deliver this callback.
  public func onConfigured(_ action: @escaping (CameraController) -> Void) -> Camera {
    var camera = self
    camera.callbacks.onConfigured = action
    return camera
  }

  /// Receives the negotiated session configuration on the main actor.
  public func onSessionConfigSelected(_ action: @escaping (CameraSessionConfig) -> Void) -> Camera {
    var camera = self
    camera.callbacks.onSessionConfigSelected = action
    return camera
  }

  /// Runs on the main actor when the capture session starts.
  public func onStarted(_ action: @escaping () -> Void) -> Camera {
    var camera = self
    camera.callbacks.onStarted = action
    return camera
  }

  /// Runs on the main actor when the mounted Camera's capture session stops.
  ///
  /// Subscriptions are removed when the view is dismantled, so removal itself does not deliver this event.
  public func onStopped(_ action: @escaping () -> Void) -> Camera {
    var camera = self
    camera.callbacks.onStopped = action
    return camera
  }

  /// Receives configuration, control, orientation, and runtime errors on the main actor.
  ///
  /// Without this callback the error is logged. Camera permission must be requested before mounting.
  public func onError(_ action: @escaping (any Error) -> Void) -> Camera {
    var camera = self
    camera.callbacks.onError = action
    return camera
  }

  /// Runs on the main actor when the capture session is interrupted.
  public func onInterruptionStarted(_ action: @escaping (InterruptionReason) -> Void) -> Camera {
    var camera = self
    camera.callbacks.onInterruptionStarted = action
    return camera
  }

  /// Runs on the main actor when the capture session's interruption ends.
  public func onInterruptionEnded(_ action: @escaping () -> Void) -> Camera {
    var camera = self
    camera.callbacks.onInterruptionEnded = action
    return camera
  }

  /// Runs on the main actor when the current device's subject area changes.
  ///
  /// Use this to reset locked focus or exposure if that matches your app's behavior.
  public func onSubjectAreaChanged(_ action: @escaping () -> Void) -> Camera {
    var camera = self
    camera.callbacks.onSubjectAreaChanged = action
    return camera
  }

  /// Runs on the main actor when the preview starts displaying frames.
  public func onPreviewStarted(_ action: @escaping () -> Void) -> Camera {
    var camera = self
    camera.callbacks.onPreviewStarted = action
    return camera
  }

  /// Runs on the main actor when the mounted preview stops displaying frames.
  public func onPreviewStopped(_ action: @escaping () -> Void) -> Camera {
    var camera = self
    camera.callbacks.onPreviewStopped = action
    return camera
  }

  /// Receives the signed rotation in degrees that keeps Camera controls upright.
  ///
  /// Values are `0`, `90`, `180`, or `-90`, relative to the preview's window scene. No event is emitted
  /// until both orientations are known, or while automatic output orientation is disabled.
  public func onUIRotationChanged(_ action: @escaping (Double) -> Void) -> Camera {
    var camera = self
    camera.callbacks.onUIRotationChanged = action
    return camera
  }

  /// Receives the underlying preview on the main actor after mounting, and `nil` after removal.
  ///
  /// Use the preview for metering points and coordinate conversions. SwiftUI owns its layout.
  /// Do not retain a removed preview or change its output and gesture controllers.
  /// The handler that receives the preview also receives its removal, even if a later view update
  /// supplies a different closure. Store the preview in an owner whose lifetime spans the mounted Camera.
  public func onPreviewChanged(_ action: @escaping (PreviewView?) -> Void) -> Camera {
    var camera = self
    camera.callbacks.onPreviewChanged = action
    return camera
  }
}
