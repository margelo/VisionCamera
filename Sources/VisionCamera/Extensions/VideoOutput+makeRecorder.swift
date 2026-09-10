extension VideoOutput {
  /// Creates and prepares a new ``Recorder`` with default settings.
  ///
  /// The recording is written to a temporary file. Preparation runs on this output's
  /// serial queue and can fail if the recording pipeline or destination cannot be prepared.
  /// See ``makeRecorder(settings:)`` to choose a destination, location metadata, or recording limits.
  ///
  /// - Returns: A prepared Recorder that can be started once.
  /// - Throws: An error if the recording pipeline cannot be prepared.
  public func makeRecorder() async throws -> Recording {
    return try await makeRecorder(settings: .init())
  }
}
