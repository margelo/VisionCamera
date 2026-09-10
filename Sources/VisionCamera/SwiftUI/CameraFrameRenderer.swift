// Copyright © 2026 Marc Rousavy @ Margelo

import SwiftUI

/// A SwiftUI view that displays Frames submitted directly to a ``FrameRenderer``.
///
/// Keep the renderer in a stable owner, such as your app's camera model, and pass the same instance
/// whenever SwiftUI updates this view. Submit Frames with ``FrameRenderer/renderFrame(frame:)`` on
/// the serial queue that delivers them. Rendering does not publish per-frame SwiftUI state.
///
/// A renderer has one display layer and can be displayed by one view at a time. Removing this view
/// detaches its layer without changing the renderer or its frame callback.
@MainActor
public struct CameraFrameRenderer: UIViewRepresentable {
  /// The renderer whose Frames this view displays.
  public var renderer: FrameRenderer
  /// How Frames fit within the view. The default is ``PreviewResizeMode/contain``.
  public var resizeMode: PreviewResizeMode

  /// Creates a SwiftUI view for an existing Frame renderer.
  /// - Parameters:
  ///   - renderer: The renderer owned by your camera model or frame pipeline.
  ///   - resizeMode: Whether Frames fit within or fill the available space.
  public init(renderer: FrameRenderer, resizeMode: PreviewResizeMode = .contain) {
    self.renderer = renderer
    self.resizeMode = resizeMode
  }

  /// Creates the underlying UIKit view. SwiftUI owns its size and position.
  public func makeUIView(context: Context) -> FrameRendererView {
    let view = FrameRendererView(frame: .zero)
    updateUIView(view, context: context)
    return view
  }

  /// Updates the renderer and scaling while preserving the UIKit view's identity.
  public func updateUIView(_ uiView: FrameRendererView, context: Context) {
    if uiView.resizeMode != resizeMode { uiView.resizeMode = resizeMode }
    if uiView.renderer !== renderer || renderer.layer.superlayer !== uiView.layer {
      uiView.renderer = renderer
    }
  }

  /// Detaches the display layer when SwiftUI removes the view.
  public static func dismantleUIView(_ uiView: FrameRendererView, coordinator: Void) {
    uiView.renderer = nil
  }
}
