import AVFoundation
import UIKit

/// A UIKit view that displays a Camera preview.
///
/// Connect a ``PreviewOutput`` both to a ``CameraSession`` and to this view's ``PreviewView/output``. All view operations run on the main actor.
@MainActor
public final class PreviewView: UIView {
  /// Sets the ``PreviewOutput`` for the ``PreviewView``.
  ///
  /// The ``PreviewOutput`` can be connected to a
  /// ``CameraSession`` to start in parallel, possibly
  /// even before the ``PreviewView`` is mounted/visible.
  public var output: PreviewOutput? {
    didSet { updatePreviewLayer() }
  }
  /// Fires when the ``PreviewView`` started.
  ///
  /// The callback runs on the main actor when the attached preview layer starts displaying Camera content.
  public var didStartPreview: (() -> Void)?
  /// Fires when the ``PreviewView`` stopped.
  ///
  /// The callback runs on the main actor when the preview stops or its output is detached.
  public var didStopPreview: (() -> Void)?
  /// Sets the ``PreviewResizeMode`` for the ``PreviewView``.
  ///
  /// The default is ``PreviewResizeMode/aspectFill``
  public var resizeMode: PreviewResizeMode = .aspectFill {
    didSet {
      if attachedLayer?.superlayer === layer { attachedLayer?.videoGravity = resizeMode.toAVLayerVideoGravity() }
    }
  }
  /// Attaches the given ``GestureController``s on this ``PreviewView``.
  ///
  /// For example, a ``ZoomGestureController`` can be attached to
  /// install a native pinch-to-zoom gesture.
  public var gestureControllers: [any GestureController] = [] {
    didSet {
      for controller in oldValue {
        removeGestureRecognizer(controller.gestureRecognizer)
        controller.detach(from: self)
      }
      for controller in gestureControllers {
        addGestureRecognizer(controller.gestureRecognizer)
        controller.attach(to: self)
      }
    }
  }
  private var attachedLayer: AVCaptureVideoPreviewLayer?
  private var isPreviewingObserver: NSKeyValueObservation?
  private var isPreviewing = false
  private var observationID = UUID()

  /// Creates a preview view attached to the given output, or an empty view when the output is `nil`.
  public init(output: PreviewOutput? = nil) {
    self.output = output
    super.init(frame: .zero)
    updatePreviewLayer()
  }

  /// Creates the view with the given frame rectangle.
  public override init(frame: CGRect) {
    super.init(frame: frame)
  }

  /// Creates the view from an archived UIKit view configuration.
  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  /// Sizes the attached preview layer to this view's bounds without implicit layer animations.
  public override func layoutSubviews() {
    super.layoutSubviews()
    guard attachedLayer?.superlayer === layer else { return }
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    attachedLayer?.frame = bounds
    CATransaction.commit()
  }

  /// Converts normalized Camera coordinates into this view's coordinates, including rotation, mirroring, and cropping.
  /// - Throws: ``PreviewError/outputNotAttached`` if the view has no attached output.
  public func point(fromCameraPoint point: CGPoint) throws(PreviewError) -> CGPoint {
    try requirePreviewLayer().layerPointConverted(fromCaptureDevicePoint: point)
  }

  /// Converts this view's coordinates into normalized Camera coordinates.
  /// - Throws: ``PreviewError/outputNotAttached`` if the view has no attached output.
  public func cameraPoint(from point: CGPoint) throws(PreviewError) -> CGPoint {
    try requirePreviewLayer().captureDevicePointConverted(fromLayerPoint: point)
  }

  /// Returns a scanned object with coordinates converted into this view's coordinate system.
  /// - Parameter object: An object delivered by ``ObjectOutput`` in Camera coordinates.
  /// - Throws: If the output is not attached or AVFoundation cannot transform the object.
  public func convertedToViewCoordinates(_ object: some ScannedObject) throws(PreviewError) -> any ScannedObject {
    let layer = try requirePreviewLayer()
    guard let transformed = layer.transformedMetadataObject(for: object.object) else {
      throw .metadataConversionFailed
    }
    return ObjectOutput.scannedObject(from: transformed)
  }

  /// Creates a metering point from a location in this view, accounting for orientation, scaling, and cropping.
  /// - Parameter point: A location in this view's coordinate system, such as a tap.
  /// - Throws: ``PreviewError/outputNotAttached`` if the view has no attached output.
  public func meteringPoint(at point: CGPoint) throws(PreviewError) -> MeteringPoint {
    let layer = try requirePreviewLayer()
    return MeteringPoint(location: layer.captureDevicePointConverted(fromLayerPoint: point))
  }

  private func requirePreviewLayer() throws(PreviewError) -> AVCaptureVideoPreviewLayer {
    guard let attachedLayer, attachedLayer.superlayer === layer else {
      throw .outputNotAttached
    }
    return attachedLayer
  }

  private func updatePreviewLayer() {
    let nextLayer = output?.previewLayer
    if nextLayer === attachedLayer, nextLayer?.superlayer === layer { return }
    isPreviewingObserver?.invalidate()
    isPreviewingObserver = nil
    if attachedLayer?.superlayer === layer { attachedLayer?.removeFromSuperlayer() }
    let wasPreviewing = isPreviewing
    isPreviewing = false
    attachedLayer = nextLayer
    if let previewLayer = nextLayer {
      layer.addSublayer(previewLayer)
      previewLayer.frame = bounds
      previewLayer.videoGravity = resizeMode.toAVLayerVideoGravity()
      let observedLayerID = ObjectIdentifier(previewLayer)
      let observationID = UUID()
      self.observationID = observationID
      isPreviewingObserver = previewLayer.observe(\.isPreviewing, options: [.initial, .new]) {
        [weak self] _, change in
        guard let value = change.newValue else { return }
        DispatchQueue.main.async { [weak self] in
          guard let self,
            let attachedLayer = self.attachedLayer,
            attachedLayer.superlayer === self.layer,
            ObjectIdentifier(attachedLayer) == observedLayerID,
            self.observationID == observationID,
            value != self.isPreviewing
          else { return }
          self.isPreviewing = value
          if value { self.didStartPreview?() } else { self.didStopPreview?() }
        }
      }
    }
    if wasPreviewing { didStopPreview?() }
  }
}
