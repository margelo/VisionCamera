import AVFoundation
import UIKit

/// A UIKit view that displays Frames submitted to a ``FrameRenderer``.
///
/// Set ``FrameRendererView/renderer`` to attach its sample-buffer display layer. All view operations run on the main actor.
@MainActor
public final class FrameRendererView: UIView {
  /// The Frame renderer displayed in this view, or `nil` to detach the current renderer.
  public var renderer: FrameRenderer? {
    didSet {
      if renderer === oldValue, renderer?.layer.superlayer === layer { return }
      if oldValue?.layer.superlayer === layer { oldValue?.layer.removeFromSuperlayer() }
      if let renderer {
        layer.addSublayer(renderer.layer)
        renderer.layer.frame = bounds
        renderer.layer.videoGravity = resizeMode.toAVLayerVideoGravity()
      }
    }
  }

  /// How Frames fit within the view. The default is ``PreviewResizeMode/aspectFit``.
  public var resizeMode: PreviewResizeMode = .aspectFit {
    didSet {
      guard renderer?.layer.superlayer === layer else { return }
      renderer?.layer.videoGravity = resizeMode.toAVLayerVideoGravity()
    }
  }

  /// Creates the view with the given frame rectangle.
  public override init(frame: CGRect) { super.init(frame: frame) }
  /// Creates the view from an archived UIKit view configuration.
  public required init?(coder: NSCoder) { super.init(coder: coder) }

  /// Sizes the renderer's display layer to this view's bounds without implicit layer animations.
  public override func layoutSubviews() {
    super.layoutSubviews()
    guard let renderer, renderer.layer.superlayer === layer else { return }
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    renderer.layer.frame = bounds
    CATransaction.commit()
  }
}
