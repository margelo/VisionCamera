import AVFoundation

@testable import VisionCamera

final class NativeAudioOutputFixture: CameraOutput, NativeCameraOutput {
  let output = AVCaptureAudioDataOutput()
  let mediaType: MediaType = .other(.audio)
  let requiresAudioInput = true
  let requiresDepthFormat = false
  let outputOrientation: CameraOrientation = .up
  let currentResolution: Size? = nil
  let streamType: StreamType = .video
  let targetResolution: ResolutionRule = .any

  func configure(config: OutputConfiguration) {}
}
