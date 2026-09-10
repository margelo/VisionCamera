//
//  TapToFocusGestureController.swift
//  VisionCamera
//
//  Created by Marc Rousavy on 04.02.26.
//

import AVFoundation
import UIKit

@MainActor
public final class TapToFocusGestureController: NSObject, GestureController,
  NativeGestureController
{
  public let gestureRecognizer = UITapGestureRecognizer()
  public weak var controller: (CameraController)? = nil

  private weak var previewView: (PreviewView)? = nil
  private var onTapListeners: [UUID: (MeteringPoint) -> Void] = [:]
  private var onFocusCompletedListeners: [UUID: (MeteringPoint) -> Void] = [:]

  public override init() {
    super.init()
    gestureRecognizer.cancelsTouchesInView = false
    gestureRecognizer.addTarget(self, action: #selector(onTap(_:)))
  }

  @objc private func onTap(_ gestureRecognizer: UITapGestureRecognizer) {
    guard let controller, let previewView else {
      return
    }

    do {
      let viewPoint = gestureRecognizer.location(in: gestureRecognizer.view)
      let meteringPoint = try previewView.createMeteringPoint(
        viewX: viewPoint.x,
        viewY: viewPoint.y,
        size: nil)
      let tapListeners = Array(onTapListeners.values)
      for listener in tapListeners { listener(meteringPoint) }

      Task { [weak self] in
        do {
          try await controller.focusTo(point: meteringPoint, options: FocusOptions())
          guard let self else { return }
          let listeners = Array(self.onFocusCompletedListeners.values)
          for listener in listeners { listener(meteringPoint) }
        } catch {
          logger.error("Failed to focus! \(error)")
        }
      }
    } catch {
      logger.error("Failed to focus! \(error)")
    }
  }

  public func addOnTapListener(onTap: @escaping (MeteringPoint) -> Void)
    -> ListenerSubscription
  {
    let id = UUID()
    onTapListeners[id] = onTap
    return ListenerSubscription { [weak self] in
      DispatchQueue.main.async { self?.onTapListeners.removeValue(forKey: id) }
    }
  }

  public func addOnFocusCompletedListener(
    onFocusCompleted: @escaping (MeteringPoint) -> Void
  ) -> ListenerSubscription {
    let id = UUID()
    onFocusCompletedListeners[id] = onFocusCompleted
    return ListenerSubscription { [weak self] in
      DispatchQueue.main.async { self?.onFocusCompletedListeners.removeValue(forKey: id) }
    }
  }

  public func onAttached(to preview: PreviewView) {
    self.previewView = preview
  }
  public func onDetached(from preview: PreviewView) {
    if self.previewView === preview {
      self.previewView = nil
    }
  }
}
