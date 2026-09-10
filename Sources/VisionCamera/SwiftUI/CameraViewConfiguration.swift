// Copyright © 2026 Marc Rousavy @ Margelo

struct CameraViewConfiguration: Equatable {
  var device: CameraDeviceOrPosition
  var outputs: [any CameraOutput]
  var constraints: [Constraint]
  var mirrorMode: MirrorMode = .auto
  var sessionConfiguration = CameraSessionConfiguration()

  func connection(preview: PreviewOutput, initialZoom: Double?, initialExposureBias: Double?) -> CameraSessionConnection {
    let outputs: [any CameraOutput] = [preview] + outputs
    return CameraSessionConnection(
      input: device,
      outputs: outputs.map { CameraOutputConfiguration(output: $0, mirrorMode: mirrorMode) },
      constraints: constraints + outputs.map { .resolution($0) },
      initialZoom: initialZoom,
      initialExposureBias: initialExposureBias)
  }

  static func == (lhs: CameraViewConfiguration, rhs: CameraViewConfiguration) -> Bool {
    let sameDevice: Bool
    switch (lhs.device, rhs.device) {
    case (.device(let lhs), .device(let rhs)): sameDevice = lhs.id == rhs.id
    case (.position(let lhs), .position(let rhs)): sameDevice = lhs == rhs
    default: sameDevice = false
    }
    return sameDevice
      && lhs.outputs.elementsEqual(rhs.outputs, by: { $0 === $1 })
      && lhs.constraints.elementsEqual(rhs.constraints, by: { $0.isEquivalent(to: $1) })
      && lhs.mirrorMode == rhs.mirrorMode
      && lhs.sessionConfiguration == rhs.sessionConfiguration
  }
}
