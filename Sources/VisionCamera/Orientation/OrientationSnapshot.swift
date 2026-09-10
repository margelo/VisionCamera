import Foundation

/// The capture session reads orientation from its queue while native callbacks update it.
/// Only the cached value is locked; callbacks always run after unlocking.
final class OrientationSnapshot {
  private let lock = NSLock()
  private var value: CameraOrientation?

  var current: CameraOrientation? {
    lock.lock()
    defer { lock.unlock() }
    return value
  }

  @discardableResult
  func update(_ orientation: CameraOrientation) -> Bool {
    lock.lock()
    defer { lock.unlock() }
    guard value != orientation else { return false }
    value = orientation
    return true
  }
}
