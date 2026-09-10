import AVFoundation
import UIKit

@MainActor
public final class PreviewView: UIView {
  public var previewOutput: CameraPreviewOutput? {
    didSet { updatePreviewLayer() }
  }
  public var onPreviewStarted: (() -> Void)?
  public var onPreviewStopped: (() -> Void)?
  public var resizeMode: PreviewResizeMode = .cover {
    didSet {
      if attachedLayer?.superlayer === layer { attachedLayer?.videoGravity = resizeMode.toAVLayerVideoGravity() }
    }
  }
  public var gestureControllers: [any GestureController] = [] {
    didSet {
      for controller in oldValue {
        removeGestureRecognizer(controller.gestureRecognizer)
        controller.onDetached(from: self)
      }
      for controller in gestureControllers {
        addGestureRecognizer(controller.gestureRecognizer)
        controller.onAttached(to: self)
      }
    }
  }
  private var attachedLayer: AVCaptureVideoPreviewLayer?
  private var isPreviewingObserver: NSKeyValueObservation?
  private var isPreviewing = false
  private var observationID = UUID()

  public init(previewOutput: CameraPreviewOutput? = nil) {
    self.previewOutput = previewOutput
    super.init(frame: .zero)
    updatePreviewLayer()
  }

  public override init(frame: CGRect) {
    super.init(frame: frame)
  }

  public required init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  public override func layoutSubviews() {
    super.layoutSubviews()
    guard attachedLayer?.superlayer === layer else { return }
    CATransaction.begin()
    CATransaction.setDisableActions(true)
    attachedLayer?.frame = bounds
    CATransaction.commit()
  }

  public func convertCameraPointToViewPoint(cameraPoint: Point) throws -> Point {
    let layer = try requirePreviewLayer()
    return Point(layer.layerPointConverted(fromCaptureDevicePoint: cameraPoint.toCGPoint()))
  }

  public func convertViewPointToCameraPoint(viewPoint: Point) throws -> Point {
    let layer = try requirePreviewLayer()
    return Point(layer.captureDevicePointConverted(fromLayerPoint: viewPoint.toCGPoint()))
  }

  public func convertScannedObjectCoordinatesToViewCoordinates(
    scannedObject: any ScannedObject
  ) throws -> any ScannedObject {
    let layer = try requirePreviewLayer()
    guard let transformed = layer.transformedMetadataObject(for: scannedObject.object) else {
      throw CameraError(message: "Cannot transform scanned object coordinates into preview coordinates.")
    }
    return CameraObjectOutput.createScannedObject(from: transformed)
  }

  public func createMeteringPoint(viewX: Double, viewY: Double, size: Double? = nil) throws -> MeteringPoint {
    let layer = try requirePreviewLayer()
    let point = layer.captureDevicePointConverted(fromLayerPoint: CGPoint(x: viewX, y: viewY))
    return MeteringPoint(
      relativeX: viewX, relativeY: viewY, relativeSize: size,
      normalizedX: point.x, normalizedY: point.y)
  }

  private func requirePreviewLayer() throws -> AVCaptureVideoPreviewLayer {
    guard let attachedLayer, attachedLayer.superlayer === layer else {
      throw CameraError(message: "PreviewView is not attached to a preview output.")
    }
    return attachedLayer
  }

  private func updatePreviewLayer() {
    let nextLayer = previewOutput?.previewLayer
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
          if value { self.onPreviewStarted?() } else { self.onPreviewStopped?() }
        }
      }
    }
    if wasPreviewing { onPreviewStopped?() }
  }
}
