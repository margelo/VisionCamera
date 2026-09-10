///
/// PhotoOutput.swift
/// VisionCamera
/// Copyright © 2025 Marc Rousavy @ Margelo
///

import AVFoundation
import Foundation
import UIKit

/// A ``ZoomGestureController`` is a ``GestureController``
/// that can modify a ``CameraController``'s
/// ``CameraController/zoom`` via a
/// native pinch-to-zoom gesture.
@MainActor
public final class ZoomGestureController: NSObject, GestureController, NativeGestureController {
  /// The UIKit gesture recognizer attached to a ``PreviewView``.
  public let gestureRecognizer = UIPinchGestureRecognizer()
  /// The Camera controller used by this gesture, held weakly.
  ///
  /// Retain the ``CameraController`` returned by ``CameraSession/configure(_:configuration:)`` elsewhere, and replace it when the session is reconfigured.
  public weak var controller: (CameraController)? = nil

  private let maximumZoomFactor = 15.0
  private var initialZoomFactor = 1.0
  private var onZoomChangedListeners: [UUID: (Double) -> Void] = [:]

  /// Creates a native pinch-to-zoom gesture controller.
  public override init() {
    super.init()
    gestureRecognizer.cancelsTouchesInView = false
    gestureRecognizer.addTarget(self, action: #selector(onPinch(_:)))
  }

  @objc private func onPinch(_ gestureRecognizer: UIPinchGestureRecognizer) {
    guard let controller else {
      return
    }
    let device = controller.captureDevice

    switch gestureRecognizer.state {
    case .began:
      initialZoomFactor = device.videoZoomFactor
    case .changed:
      let targetFactor = initialZoomFactor * gestureRecognizer.scale
      let minZoom = device.minAvailableVideoZoomFactor
      let maxZoom = min(device.maxAvailableVideoZoomFactor, maximumZoomFactor)
      let zoom = min(max(targetFactor, minZoom), maxZoom)
      let listeners = Array(onZoomChangedListeners.values)

      for listener in listeners { listener(zoom) }

      controller.queue.async(
        execute: DispatchWorkItem {
          do {
            try device.lockForConfiguration()
            device.videoZoomFactor = zoom
            device.unlockForConfiguration()
          } catch {
            logger.error("Failed to lock device for zooming! \(error)")
          }
        })
    default:
      break
    }
  }

  /// Adds a listener that is called whenever this native pinch gesture
  /// changes the target zoom factor.
  ///
  /// The listener can be called many times during one pinch gesture.
  /// Retain the returned token while observing. Cancel or release it to stop receiving updates.
  public func observeZoomChanges(_ onZoomChanged: @escaping (Double) -> Void)
    -> ObservationToken
  {
    let id = UUID()
    onZoomChangedListeners[id] = onZoomChanged
    return ObservationToken { [weak self] in
      DispatchQueue.main.async { self?.onZoomChangedListeners.removeValue(forKey: id) }
    }
  }
}
