// Copyright © 2025 Marc Rousavy @ Margelo

@MainActor
public protocol GestureController: NativeGestureController {
  var controller: CameraController? { get set }
}
