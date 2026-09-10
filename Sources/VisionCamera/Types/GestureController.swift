// Copyright © 2025 Marc Rousavy @ Margelo

/// A ``GestureController`` is a controller
/// that can control a ``CameraController``'s
/// property via a user gesture.
///
/// For example, a ``ZoomGestureController``
/// uses a pinch gesture to modify the ``CameraController``'s
/// ``CameraController/zoom`` property.
///
/// The ``GestureController`` needs to be attached
/// to a View (like a ``PreviewView``) to enable
/// the gesture.
@MainActor
public protocol GestureController: NativeGestureController {
  /// Gets or sets the ``CameraController``
  /// this ``GestureController`` should
  /// control.
  ///
  /// The supplied gesture controllers hold this reference weakly. Keep the Camera controller alive while
  /// gestures should control it.
  var controller: CameraController? { get set }
}
