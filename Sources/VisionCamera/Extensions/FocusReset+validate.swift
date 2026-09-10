// Copyright © 2026 Marc Rousavy @ Margelo

extension FocusReset {
  func validate() throws {
    if case .after(let seconds) = self {
      guard seconds.isFinite, seconds >= 0 else {
        throw CameraControlError.invalidFocusResetDelay
      }
    }
  }
}
