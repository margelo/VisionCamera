// Copyright © 2026 Marc Rousavy @ Margelo

import UIKit

/// Observes only the scene displaying a preview, and releases its subscription when detached.
@MainActor
final class PreviewOrientationObserver {
  private weak var scene: UIWindowScene?
  private var geometryObserver: NSKeyValueObservation?
  private var deviceObserver: NSObjectProtocol?
  private var onChanged: ((CameraOrientation) -> Void)?
  private var lastOrientation: CameraOrientation?

  func start(scene: UIWindowScene, onChanged: @escaping (CameraOrientation) -> Void) {
    guard self.scene !== scene else {
      self.onChanged = onChanged
      update()
      return
    }
    stop()
    self.scene = scene
    self.onChanged = onChanged
    if #available(iOS 16.0, *) {
      geometryObserver = scene.observe(\.effectiveGeometry, options: [.new]) { [weak self, weak scene] _, _ in
        DispatchQueue.main.async { [weak self, weak scene] in
          guard let self, let scene, self.scene === scene else { return }
          self.update()
        }
      }
    } else {
      UIDevice.current.beginGeneratingDeviceOrientationNotifications()
      deviceObserver = NotificationCenter.default.addObserver(
        forName: UIDevice.orientationDidChangeNotification, object: nil, queue: .main
      ) { [weak self, weak scene] _ in
        DispatchQueue.main.async { [weak self, weak scene] in
          guard let self, let scene, self.scene === scene else { return }
          self.update()
        }
      }
    }
    update()
  }

  func update() {
    guard let scene else { return }
    let interfaceOrientation: UIInterfaceOrientation
    if #available(iOS 16.0, *) {
      interfaceOrientation = scene.effectiveGeometry.interfaceOrientation
    } else {
      interfaceOrientation = scene.interfaceOrientation
    }
    guard interfaceOrientation != .unknown else { return }
    let orientation = CameraOrientation(interfaceOrientation: interfaceOrientation)
    guard orientation != lastOrientation else { return }
    lastOrientation = orientation
    onChanged?(orientation)
  }

  func stop() {
    geometryObserver?.invalidate()
    geometryObserver = nil
    if let deviceObserver {
      NotificationCenter.default.removeObserver(deviceObserver)
      self.deviceObserver = nil
      UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }
    scene = nil
    onChanged = nil
    lastOrientation = nil
  }

  deinit {
    geometryObserver?.invalidate()
    if let deviceObserver {
      NotificationCenter.default.removeObserver(deviceObserver)
      DispatchQueue.main.async { UIDevice.current.endGeneratingDeviceOrientationNotifications() }
    }
  }
}
