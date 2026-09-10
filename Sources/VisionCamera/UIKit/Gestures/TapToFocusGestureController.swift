//
//  TapToFocusGestureController.swift
//  VisionCamera
//
//  Created by Marc Rousavy on 04.02.26.
//

import AVFoundation
import UIKit

/// A ``TapToFocusGestureController`` is a ``GestureController``
/// that can trigger a ``CameraController``'s
/// ``CameraController/focus(at:options:)``
/// action via a native tap to focus gesture.
@MainActor
public final class TapToFocusGestureController: NSObject, GestureController,
  NativeGestureController
{
  /// The UIKit gesture recognizer attached to a ``PreviewView``.
  public let gestureRecognizer = UITapGestureRecognizer()
  /// The Camera controller used by this gesture, held weakly.
  ///
  /// Retain the ``CameraController`` returned by ``CameraSession/configure(_:configuration:)`` elsewhere, and replace it when the session is reconfigured.
  public weak var controller: (CameraController)? = nil

  private weak var previewView: (PreviewView)? = nil
  private var onTapListeners: [UUID: (MeteringPoint) -> Void] = [:]
  private var onFocusCompletedListeners: [UUID: (MeteringPoint) -> Void] = [:]

  /// Creates a native tap-to-focus gesture controller.
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
      let meteringPoint = try previewView.meteringPoint(at: viewPoint)
      let tapListeners = Array(onTapListeners.values)
      for listener in tapListeners { listener(meteringPoint) }

      Task { [weak self] in
        do {
          try await controller.focus(at: meteringPoint, options: FocusOptions())
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

  /// Adds a listener that is called when a native tap gesture creates a
  /// ``MeteringPoint``, immediately before focusing begins.
  ///
  /// Retain the returned token while observing. Cancel or release it to stop receiving updates.
  public func observeTaps(_ onTap: @escaping (MeteringPoint) -> Void)
    -> ObservationToken
  {
    let id = UUID()
    onTapListeners[id] = onTap
    return ObservationToken { [weak self] in
      DispatchQueue.main.async { self?.onTapListeners.removeValue(forKey: id) }
    }
  }

  /// Adds a listener that is called when the focus operation triggered by a
  /// native tap completes.
  ///
  /// This is not called if the focus operation fails. Call
  /// ``ObservationToken/cancel()`` on the returned
  /// subscription to stop receiving updates.
  public func observeFocusCompletion(
    _ onFocusCompleted: @escaping (MeteringPoint) -> Void
  ) -> ObservationToken {
    let id = UUID()
    onFocusCompletedListeners[id] = onFocusCompleted
    return ObservationToken { [weak self] in
      DispatchQueue.main.async { self?.onFocusCompletedListeners.removeValue(forKey: id) }
    }
  }

  /// Associates this tap gesture with the Preview View used to convert tap coordinates into a Metering CGPoint.
  public func attach(to preview: PreviewView) {
    self.previewView = preview
  }
  /// Clears the attached Preview View when this gesture is removed.
  public func detach(from preview: PreviewView) {
    if self.previewView === preview {
      self.previewView = nil
    }
  }
}
