// Copyright © 2026 Marc Rousavy @ Margelo

import Foundation

extension CameraCoordinator {
  func updateSubjectSubscription() {
    guard let controller, camera?.callbacks.onSubjectAreaChanged != nil else {
      subjectSubscription?.cancel()
      subjectSubscription = nil
      return
    }
    guard subjectSubscription == nil else { return }
    // Registering and removing this listener locks the capture device to change its monitoring flag.
    subjectSubscription = CameraQueuedSubscription(queue: CameraSession.queue) { [weak self] in
      controller.observeSubjectAreaChanges { [weak self, weak controller] in
        DispatchQueue.main.async {
          guard let self, let controller, self.controller === controller else { return }
          self.camera?.callbacks.onSubjectAreaChanged?()
        }
      }
    }
  }
}
