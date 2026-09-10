// Copyright © 2025 Marc Rousavy @ Margelo

/// The ``OrientationManager`` allows listening to
/// ``CameraOrientation`` changes, like device- or interface-
/// orientation.
public protocol OrientationManager: AnyObject {
  /// Represents the ``OrientationSource`` this ``OrientationManager``
  /// is tracking.
  var source: OrientationSource { get }
  /// Get the current ``CameraOrientation``, or `nil` if no
  /// orientation is known.
  var currentOrientation: CameraOrientation? { get }

  /// Starts listening to orientation changes.
  ///
  /// - Parameter onChanged: Receives orientation changes. Interface updates run on the main queue; device updates run on the manager's serial queue.
  /// - Throws: An error if device orientation is requested when accelerometer data is unavailable.
  func startOrientationUpdates(onChanged: @escaping (_ orientation: CameraOrientation) -> Void) throws
  /// Stops listening to orientation changes.
  ///
  /// Removal is submitted to the manager's owning queue. An update already in flight may still be delivered.
  func stopOrientationUpdates()
}
