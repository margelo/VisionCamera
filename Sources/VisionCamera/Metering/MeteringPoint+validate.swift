// Copyright © 2026 Marc Rousavy @ Margelo

extension MeteringPoint {
  func validate() throws {
    guard location.x.isFinite, location.y.isFinite,
      (0...1).contains(location.x), (0...1).contains(location.y)
    else {
      throw CameraControlError.invalidMeteringPoint
    }
  }
}
