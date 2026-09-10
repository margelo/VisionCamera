// Copyright © 2026 Marc Rousavy @ Margelo

import CoreMotion
import Foundation

public final class DeviceOrientationManager: OrientationManager {
  public let source: OrientationSource = .device
  public var currentOrientation: CameraOrientation? { orientation.current }
  private let orientation = OrientationSnapshot()
  private let motionManager = CMMotionManager()
  private let queue = DispatchQueue(label: "com.margelo.camera.device-orientation")
  private let operationQueue = OperationQueue()
  private let isAvailable: Bool
  private var subscriptionID: UUID?

  public init() {
    isAvailable = motionManager.isAccelerometerAvailable
    motionManager.accelerometerUpdateInterval = 0.2
    operationQueue.maxConcurrentOperationCount = 1
    operationQueue.underlyingQueue = queue
  }

  /// Calls `onChanged` on the manager's serial orientation queue.
  public func startOrientationUpdates(onChanged: @escaping (CameraOrientation) -> Void) throws {
    guard isAvailable else {
      throw CameraError(message: "Cannot listen to device orientation changes: accelerometer is not available.")
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

  public func stopOrientationUpdates() {
    queue.async(
      execute: DispatchWorkItem { [weak self] in
        guard let self else { return }
        self.subscriptionID = nil
        self.motionManager.stopAccelerometerUpdates()
      })
  }

  deinit { motionManager.stopAccelerometerUpdates() }
}
