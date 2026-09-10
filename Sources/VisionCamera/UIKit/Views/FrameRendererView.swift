import AVFoundation
import UIKit

@MainActor
public final class FrameRendererView: UIView {
  public var renderer: FrameRenderer? {
    didSet {
      if renderer === oldValue, renderer?.layer.superlayer === layer { return }
      if oldValue?.layer.superlayer === layer { oldValue?.layer.removeFromSuperlayer() }
      if let renderer {
        layer.addSublayer(renderer.layer)
        renderer.layer.frame = bounds
      }
    }
  }

  public override init(frame: CGRect) { super.init(frame: frame) }
  public required init?(coder: NSCoder) { super.init(coder: coder) }

  public override func layoutSubviews() {
    super.layoutSubviews()
    guard let renderer, renderer.layer.superlayer === layer else { return }
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    renderer.layer.frame = bounds
    CATransaction.commit()
  }
}
