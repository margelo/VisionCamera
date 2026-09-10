// Copyright © 2025 Marc Rousavy @ Margelo

extension Recorder {
  /// Starts recording without pause or resume callbacks.
  ///
  /// Returns when recording has started. The finished handler receives the finalized file later, on the recorder's owning queue.
  /// - Parameters:
  ///   - onFinished: Called after the video file has been finalized.
  ///   - onError: Called if the active recording fails after starting.
  /// - Throws: An error if the recording cannot start.
  public func start(
    onFinished: @escaping (RecordingResult) -> Void,
    onError: @escaping (any Error) -> Void
  ) async throws {
    try await start(onFinished: onFinished, onError: onError, onPaused: nil, onResumed: nil)
  }
}
