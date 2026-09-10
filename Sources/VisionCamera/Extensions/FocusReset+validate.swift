// Copyright © 2026 Marc Rousavy @ Margelo

extension FocusReset {
  func validate() throws {
    if case .after(let seconds) = self {
      guard seconds.isFinite, seconds >= 0 else {
        throw CameraError(message: "The focus reset delay must be finite and nonnegative.")
      }
    }
  }
}
