// Copyright © 2025 Marc Rousavy @ Margelo

public protocol OrientationManager: AnyObject {
  var source: OrientationSource { get }
  var currentOrientation: CameraOrientation? { get }

  func startOrientationUpdates(onChanged: @escaping (_ orientation: CameraOrientation) -> Void) throws
  func stopOrientationUpdates() throws
}
