//
//  ResolvedCameraSessionConnection.swift
//  VisionCamera
//
//  Created by Marc Rousavy on 07.01.26.
//

import AVFoundation

/// Represents a resolved `CameraSessionConnection`.
struct ResolvedCameraSessionConnection {
  let input: CameraDevice
  let outputs: [OutputConfiguration]
  let initialExposureBias: Double?
  let initialZoom: Double?
  let onSessionConfigSelected: ((_ config: (CameraSessionConfig)) -> Void)?
  let constraints: [Constraint]

  init(connection: CameraSessionConnection) throws {
    self.input = try Self.resolveInput(connection.input)
    self.outputs = try connection.outputs.map { try Self.resolveOutput($0) }
    self.initialExposureBias = connection.initialExposureBias
    self.initialZoom = connection.initialZoom
    self.onSessionConfigSelected = connection.onSessionConfigSelected
    self.constraints = connection.constraints
  }

  var requiresAudioInput: Bool {
    return outputs.contains { $0.output.requiresAudioInput }
  }

  func isConnectedTo(input: AVCaptureInput) -> Bool {
    guard let deviceInput = input as? AVCaptureDeviceInput else {
      return false
    }
    return deviceInput.device == self.input.device
  }
  func isConnectedTo(output avOutput: AVCaptureOutput) -> Bool {
    return outputs.contains { outputConfiguration in
      switch outputConfiguration.output {
      case .output(let output):
        return output.output == avOutput
      case .preview:
        return false
      }
    }
  }
  func isConnectedTo(preview previewLayer: AVCaptureVideoPreviewLayer) -> Bool {
    return outputs.contains { outputConfiguration in
      switch outputConfiguration.output {
      case .output:
        return false
      case .preview(let preview):
        return preview.previewLayer == previewLayer
      }
    }
  }
  func contains(connection: AVCaptureConnection) -> Bool {
    guard let input = connection.deviceInput else {
      return false
    }
    if let output = connection.output {
      return isConnectedTo(input: input) && isConnectedTo(output: output)
    } else if let preview = connection.videoPreviewLayer {
      return isConnectedTo(input: input) && isConnectedTo(preview: preview)
    } else {
      fatalError("AVCaptureConnection does not have .output or .videoPreviewLayer!")
    }
  }

  struct OutputConfiguration {
    let output: Output
    let mirrorMode: MirrorMode
  }
  enum Output {
    case output(any CameraOutput & NativeCameraOutput)
    case preview(any CameraOutput & NativePreviewViewOutput)

    var requiresAudioInput: Bool {
      switch self {
      case .output(let output):
        return output.requiresAudioInput
      case .preview:
        return false
      }
    }

    var mediaType: MediaType {
      switch self {
      case .output(let output):
        return output.mediaType
      case .preview(let preview):
        return preview.mediaType
      }
    }

    var cameraOutput: any CameraOutput {
      switch self {
      case .output(let output):
        return output
      case .preview(let preview):
        return preview
      }
    }
  }

  private static func resolveInput(_ input: CameraDeviceOrPosition) throws -> CameraDevice {
    switch input {
    case .device(let device):
      return device
    case .position(let targetCameraPosition):
      guard let device = AVCaptureDevice.default(for: targetCameraPosition) else {
        throw ConfigurationError.cameraUnavailable(position: targetCameraPosition)
      }
      return CameraDevice(device: device)
    }
  }
  private static func resolveOutput(_ outputConfiguration: CameraOutputConfiguration) throws -> OutputConfiguration {
    switch outputConfiguration.output {
    case let nativeOutput as any CameraOutput & NativeCameraOutput:
      // It's a normal AVCaptureOutput
      return OutputConfiguration(
        output: .output(nativeOutput),
        mirrorMode: outputConfiguration.mirrorMode)
    case let nativePreview as any CameraOutput & NativePreviewViewOutput:
      return OutputConfiguration(
        output: .preview(nativePreview),
        mirrorMode: outputConfiguration.mirrorMode)
    default:
      throw ConfigurationError.unsupportedOutput(outputType: String(describing: type(of: outputConfiguration.output)))
    }
  }
}
