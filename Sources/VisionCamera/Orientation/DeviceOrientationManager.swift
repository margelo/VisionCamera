// Copyright © 2026 Marc Rousavy @ Margelo

import CoreMotion
import Foundation

/// The ``DeviceOrientationManager`` allows listening to ``CameraOrientation`` changes from the device's accelerometer.
public final class DeviceOrientationManager: OrientationManager {
  /// Represents the ``OrientationSource`` this ``OrientationManager``
  /// is tracking.
  public let source: OrientationSource = .device
  /// Get the current ``CameraOrientation``, or `nil` if no
  /// orientation is known.
  public var currentOrientation: CameraOrientation? { orientation.current }
  private let orientation = OrientationSnapshot()
  private let motionManager = CMMotionManager()
  private let queue = DispatchQueue(label: "com.margelo.camera.device-orientation")
  private let operationQueue = OperationQueue()
  private let isAvailable: Bool
  private var subscriptionID: UUID?

  /// Creates a manager for physical device orientation using the accelerometer.
  public init() {
    isAvailable = motionManager.isAccelerometerAvailable
    motionManager.accelerometerUpdateInterval = 0.2
    operationQueue.maxConcurrentOperationCount = 1
    operationQueue.underlyingQueue = queue
  }

  /// Starts listening to orientation changes.
  ///
  /// Starting updates replaces the previous callback. Callbacks run on this manager's serial orientation queue. Throws if the accelerometer is unavailable.
  public func startUpdates(_ onChanged: @escaping (CameraOrientation) -> Void) throws(OrientationError) {
    guard isAvailable else {
      throw OrientationError.accelerometerUnavailable
    }
    queue.async(
      execute: DispatchWorkItem { [weak self] in
        guard let self else { return }
        self.motionManager.stopAccelerometerUpdates()
        let id = UUID()
        self.subscriptionID = id
        if let orientation = self.orientation.current { onChanged(orientation) }
        self.motionManager.startAccelerometerUpdates(to: self.operationQueue) { [weak self] data, error in
          guard let self, self.subscriptionID == id else { return }
          if let error { logger.error("Accelerometer update failed: \(error)") }
          guard let orientation = data?.deviceOrientation else { return }
          if self.orientation.update(orientation) { onChanged(orientation) }
        }
      })
  }

  /// Stops listening to orientation changes.
  ///
  /// Stops delivery on the manager's owning queue. A callback already in progress may finish before removal takes effect.
  public func stopUpdates() {
    queue.async(
      execute: DispatchWorkItem { [weak self] in
        guard let self else { return }
        self.subscriptionID = nil
        self.motionManager.stopAccelerometerUpdates()
      })
  }

  deinit { motionManager.stopAccelerometerUpdates() }
}
