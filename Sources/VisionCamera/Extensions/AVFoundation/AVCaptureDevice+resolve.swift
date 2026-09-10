import AVFoundation

extension AVCaptureDevice {
  static func resolve(value: CameraDeviceOrPosition) throws -> AVCaptureDevice {
    switch value {
    case .device(let camera):
      return camera.device
    case .position(let position):
      guard let device = AVCaptureDevice.default(for: position) else {
        throw CameraError(message: "No camera exists at position \(position).")
      }
      return device
    }
  }
}
