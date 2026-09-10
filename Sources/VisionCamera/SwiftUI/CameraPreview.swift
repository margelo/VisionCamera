// Copyright © 2026 Marc Rousavy @ Margelo

import SwiftUI

/// A SwiftUI preview for a ``PreviewOutput`` connected to a session you own.
///
/// Use ``Camera`` when the view should configure and run the session. Use this view when your app
/// manages ``CameraSession`` directly, for example for multiple cameras or a persistent capture pipeline.
/// Keep the output and any gesture controllers in a stable owner instead of creating them in `body`.
///
/// A preview output has one layer and can be displayed by one view at a time. Removing the view
/// detaches its layer and gesture controllers. It does not stop your session or disconnect its outputs.
@MainActor
public struct CameraPreview: UIViewRepresentable {
  /// The preview output to display, or `nil` for an empty preview.
  public var previewOutput: PreviewOutput?
  /// How the preview fits within the view. The default is ``PreviewResizeMode/cover``.
  public var resizeMode: PreviewResizeMode
  /// Native gesture controllers to attach, in recognition order.
  public var gestureControllers: [any GestureController]
  /// Called on the main actor when the attached preview starts displaying Frames.
  public var onPreviewStarted: (() -> Void)?
  /// Called on the main actor when the attached preview stops displaying Frames.
  public var onPreviewStopped: (() -> Void)?

  /// Creates a preview for an existing Camera pipeline.
  /// - Parameters:
  ///   - previewOutput: The preview output connected to your session.
  ///   - resizeMode: Whether the preview fills or fits within the available space.
  ///   - gestureControllers: Stable native gesture controllers configured with your ``CameraController``.
  ///   - onPreviewStarted: Called when the preview starts displaying Frames.
  ///   - onPreviewStopped: Called when the preview stops displaying Frames while mounted.
  public init(
    previewOutput: PreviewOutput?,
    resizeMode: PreviewResizeMode = .cover,
    gestureControllers: [any GestureController] = [],
    onPreviewStarted: (() -> Void)? = nil,
    onPreviewStopped: (() -> Void)? = nil
  ) {
    self.previewOutput = previewOutput
    self.resizeMode = resizeMode
    self.gestureControllers = gestureControllers
    self.onPreviewStarted = onPreviewStarted
    self.onPreviewStopped = onPreviewStopped
  }

  /// Creates the underlying UIKit view. SwiftUI owns its size and position.
  public func makeUIView(context: Context) -> PreviewView {
    let view = PreviewView()
    updateUIView(view, context: context)
    return view
  }

  /// Updates presentation and event handlers without reconfiguring the Camera session.
  public func updateUIView(_ uiView: PreviewView, context: Context) {
    uiView.onPreviewStarted = onPreviewStarted
    uiView.onPreviewStopped = onPreviewStopped
    if uiView.resizeMode != resizeMode { uiView.resizeMode = resizeMode }
    let hasSameGestures =
      uiView.gestureControllers.count == gestureControllers.count
      && zip(uiView.gestureControllers, gestureControllers).allSatisfy { $0 === $1 }
    if !hasSameGestures { uiView.gestureControllers = gestureControllers }
    uiView.previewOutput = previewOutput
  }

  /// Removes callbacks, gestures, and the preview layer when SwiftUI removes the view.
  public static func dismantleUIView(_ uiView: PreviewView, coordinator: Void) {
    uiView.onPreviewStarted = nil
    uiView.onPreviewStopped = nil
    uiView.onInterfaceOrientationChanged = nil
    uiView.gestureControllers = []
    uiView.previewOutput = nil
  }
}
