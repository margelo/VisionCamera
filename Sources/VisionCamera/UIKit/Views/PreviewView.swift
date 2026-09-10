import AVFoundation
import UIKit

/// A UIKit view that displays a Camera preview.
///
/// Connect a ``PreviewOutput`` both to a ``CameraSession`` and to this view's ``PreviewView/previewOutput``. All view operations run on the main actor.
@MainActor
public final class PreviewView: UIView {
  /// Sets the ``PreviewOutput`` for the ``PreviewView``.
  ///
  /// The ``PreviewOutput`` can be connected to a
  /// ``CameraSession`` to start in parallel, possibly
  /// even before the ``PreviewView`` is mounted/visible.
  public var previewOutput: PreviewOutput? {
    didSet { updatePreviewLayer() }
  }
  /// Fires when the ``PreviewView`` started.
  ///
  /// The callback runs on the main actor when the attached preview layer starts displaying Camera content.
  public var onPreviewStarted: (() -> Void)?
  /// Fires when the ``PreviewView`` stopped.
  ///
  /// The callback runs on the main actor when the preview stops or its output is detached.
  public var onPreviewStopped: (() -> Void)?
  /// Sets the ``PreviewResizeMode`` for the ``PreviewView``.
  ///
  /// The default is 'cover'
  public var resizeMode: PreviewResizeMode = .cover {
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

  /// Creates a preview view attached to the given output, or an empty view when the output is `nil`.
  public init(previewOutput: PreviewOutput? = nil) {
    self.previewOutput = previewOutput
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

  /// Converts the given `cameraPoint` in
  /// camera sensor coordinates into a ``Point``
  /// in view coordinates, relative to this ``PreviewView``.
  ///
  /// Capture-device coordinates range from `0` to `1`, relative to the unrotated image. The conversion accounts for preview orientation, mirroring, and video gravity.
  /// - Throws: If the ``PreviewView`` isn't ready yet.
  ///
  /// ```swift
  /// let point = try previewView.convertCameraPointToViewPoint(cameraPoint: Point(x: 0.5, y: 0.5))
  /// ```
  public func convertCameraPointToViewPoint(cameraPoint: Point) throws -> Point {
    let layer = try requirePreviewLayer()
    return Point(layer.layerPointConverted(fromCaptureDevicePoint: cameraPoint.toCGPoint()))
  }

  /// Converts the given `viewPoint` in
  /// view coordinates relative to this ``PreviewView``
  /// into a ``Point`` in camera sensor coordinates.
  ///
  /// Capture-device coordinates range from `0` to `1`, relative to the unrotated image. The conversion accounts for preview orientation, mirroring, and video gravity.
  /// - Throws: If the ``PreviewView`` isn't ready yet.
  ///
  /// ```swift
  /// let point = try previewView.convertViewPointToCameraPoint(viewPoint: Point(x: 196, y: 379.5))
  /// ```
  public func convertViewPointToCameraPoint(viewPoint: Point) throws -> Point {
    let layer = try requirePreviewLayer()
    return Point(layer.captureDevicePointConverted(fromLayerPoint: viewPoint.toCGPoint()))
  }

  /// Returns a new ``ScannedObject`` where all coordinates
  /// in the given `scannedObject` are converted into
  /// view coordinates.
  /// - Parameter scannedObject: The scanned object in its original coordinates.
  public func convertScannedObjectCoordinatesToViewCoordinates(
    scannedObject: any ScannedObject
  ) throws -> any ScannedObject {
    let layer = try requirePreviewLayer()
    guard let transformed = layer.transformedMetadataObject(for: scannedObject.object) else {
      throw CameraError(message: "Cannot transform scanned object coordinates into preview coordinates.")
    }
    return ObjectOutput.scannedObject(from: transformed)
  }

  /// Creates a ``MeteringPoint`` that can be used for
  /// setting focus and exposure points of interest via ``CameraController/focusTo(point:options:)``.
  ///
  /// The point is relative to this
  /// ``PreviewView``, and takes orientation, scaling and cropping
  /// into account.
  /// - Parameter point: A point in the View's coordinate system, such as the location of a tap.
  ///
  /// - Throws: If the ``PreviewView`` isn't ready yet.
  public func meteringPoint(at point: CGPoint) throws -> MeteringPoint {
    let layer = try requirePreviewLayer()
    let normalizedPoint = layer.captureDevicePointConverted(fromLayerPoint: point)
    return MeteringPoint(
      normalizedX: normalizedPoint.x, normalizedY: normalizedPoint.y)
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
