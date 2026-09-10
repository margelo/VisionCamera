///
/// CameraPhotoOutput.swift
/// VisionCamera
/// Copyright © 2025 Marc Rousavy @ Margelo
///

import AVFoundation
import Foundation
import UIKit

@MainActor
public final class ZoomGestureController: NSObject, GestureController, NativeGestureController {
  public let gestureRecognizer = UIPinchGestureRecognizer()
  public weak var controller: (CameraController)? = nil

  private let maximumZoomFactor = 15.0
  private var initialZoomFactor = 1.0
  private var onZoomChangedListeners: [UUID: (Double) -> Void] = [:]

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

  public func addOnZoomChangedListener(onZoomChanged: @escaping (Double) -> Void)
    -> ListenerSubscription
  {
    let id = UUID()
    onZoomChangedListeners[id] = onZoomChanged
    return ListenerSubscription { [weak self] in
      DispatchQueue.main.async { self?.onZoomChangedListeners.removeValue(forKey: id) }
    }
  }
}
