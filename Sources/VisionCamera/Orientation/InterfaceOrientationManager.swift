// Copyright © 2026 Marc Rousavy @ Margelo

import Foundation
import UIKit

/// The ``InterfaceOrientationManager`` allows listening to ``CameraOrientation`` changes from the foreground window scene.
public final class InterfaceOrientationManager: OrientationManager {
  /// Represents the ``OrientationSource`` this ``OrientationManager``
  /// is tracking.
  public let source: OrientationSource = .interface
  /// Get the current ``CameraOrientation``, or `nil` if no
  /// orientation is known.
  public var currentOrientation: CameraOrientation? { orientation.current }
  private let orientation = OrientationSnapshot()
  private var observer: NSObjectProtocol?
  private var subscriptionID: UUID?

  /// Creates a manager for the foreground window scene's interface orientation.
  public init() {
    DispatchQueue.main.async { [weak self] in
      let interfaceOrientation = UIApplication.shared.interfaceOrientation
      guard interfaceOrientation != .unknown else { return }
      self?.orientation.update(CameraOrientation(interfaceOrientation: interfaceOrientation))
    }
  }

  /// Starts listening to orientation changes.
  ///
  /// Starting updates replaces the previous callback. Callbacks run on the main queue.
  public func startOrientationUpdates(onChanged: @escaping (CameraOrientation) -> Void) {
    DispatchQueue.main.async { [weak self] in
      guard let self else { return }
      if let observer = self.observer {
        NotificationCenter.default.removeObserver(observer)
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
      }
      let id = UUID()
      self.subscriptionID = id
      UIDevice.current.beginGeneratingDeviceOrientationNotifications()

      let interfaceOrientation = UIApplication.shared.interfaceOrientation
      if interfaceOrientation != .unknown {
        let orientation = CameraOrientation(interfaceOrientation: interfaceOrientation)
        self.orientation.update(orientation)
        onChanged(orientation)
      }

      self.observer = NotificationCenter.default.addObserver(
        forName: UIDevice.orientationDidChangeNotification, object: nil, queue: .main
      ) { [weak self] _ in
        guard let self, self.subscriptionID == id else { return }
        let interfaceOrientation = UIApplication.shared.interfaceOrientation
        guard interfaceOrientation != .unknown else { return }
        let orientation = CameraOrientation(interfaceOrientation: interfaceOrientation)
        if self.orientation.update(orientation) { onChanged(orientation) }
      }
    }
  }

  /// Stops listening to orientation changes.
  ///
  /// Stops delivery on the manager's owning queue. A callback already in progress may finish before removal takes effect.
  public func stopOrientationUpdates() {
    DispatchQueue.main.async { [weak self] in
      guard let self else { return }
      self.subscriptionID = nil
      if let observer = self.observer {
        NotificationCenter.default.removeObserver(observer)
        self.observer = nil
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
      }
    }
  }

  deinit {
    if let observer {
      NotificationCenter.default.removeObserver(observer)
      DispatchQueue.main.async { UIDevice.current.endGeneratingDeviceOrientationNotifications() }
    }
  }
}
