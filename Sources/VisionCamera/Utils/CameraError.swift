import Foundation

public struct CameraError: LocalizedError {
  public let message: String

  public init(message: String) {
    self.message = message
  }

  public var errorDescription: String? { message }
}
