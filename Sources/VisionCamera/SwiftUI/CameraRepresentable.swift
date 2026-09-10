// Copyright © 2026 Marc Rousavy @ Margelo

import SwiftUI

struct CameraRepresentable: UIViewRepresentable {
  let camera: Camera

  func makeCoordinator() -> CameraCoordinator {
    return CameraCoordinator()
  }

  func makeUIView(context: Context) -> PreviewView {
    let preview = PreviewView()
    context.coordinator.mount(camera: camera, preview: preview)
    return preview
  }

  func updateUIView(_ preview: PreviewView, context: Context) {
    context.coordinator.update(camera: camera)
  }

  static func dismantleUIView(_ preview: PreviewView, coordinator: CameraCoordinator) {
    coordinator.dismantle()
  }
}
