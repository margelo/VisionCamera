// Copyright © 2025 Marc Rousavy @ Margelo

public protocol CameraVideoOutput: CameraOutput {
  func getSupportedVideoCodecs() throws -> [VideoCodec]
  func setOutputSettings(settings: VideoOutputSettings) async throws
  func createRecorder(settings: RecorderSettings) async throws -> any Recorder
}
