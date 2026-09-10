// Copyright © 2026 Marc Rousavy @ Margelo

extension MeteringPoint {
  func validate() throws {
    guard normalizedX.isFinite, normalizedY.isFinite,
      (0...1).contains(normalizedX), (0...1).contains(normalizedY)
    else {
      throw CameraError(message: "Metering coordinates must be finite values within 0...1.")
    }
  }
}
