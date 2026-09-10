import Foundation

/// An error describing a Camera configuration, capture, conversion, or lifetime failure.
public struct CameraError: LocalizedError {
  /// The human-readable description of the Camera error.
  public let message: String

  /// Creates a Camera error with the given message.
  public init(message: String) {
    self.message = message
  }

  /// The message exposed through `LocalizedError`.
  public var errorDescription: String? { message }
}
