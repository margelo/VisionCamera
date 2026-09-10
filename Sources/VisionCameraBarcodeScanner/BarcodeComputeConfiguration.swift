// Copyright © 2026 Marc Rousavy @ Margelo

import CoreML
import Vision

@available(iOS 16.0, *)
struct BarcodeComputeConfiguration {
  private let configure: (VNDetectBarcodesRequest) -> Void

  init(request: VNDetectBarcodesRequest) throws {
    #if targetEnvironment(simulator)
      // The simulator can advertise acceleration that fails to create a Vision inference context.
      // Select supported CPU devices once, retaining the same ML request revision as physical devices.
      if #available(iOS 17.0, *) {
        let devices = try request.supportedComputeStageDevices.compactMapValues { devices in
          devices.first { device in
            if case .cpu = device { return true }
            return false
          }
        }
        self.configure = { request in
          for (stage, device) in devices { request.setComputeDevice(device, for: stage) }
        }
      } else {
        self.configure = { request in request.usesCPUOnly = true }
      }
    #else
      self.configure = { _ in }
    #endif
  }

  func apply(to request: VNDetectBarcodesRequest) {
    configure(request)
  }
}
