import Foundation

extension Bundle {
  func requireCameraUsageDescription() throws {
    guard object(forInfoDictionaryKey: "NSCameraUsageDescription") != nil else {
      throw CameraError(message: "Add NSCameraUsageDescription to Info.plist before requesting camera access.")
    }
  }

  func requireMicrophoneUsageDescription() throws {
    guard object(forInfoDictionaryKey: "NSMicrophoneUsageDescription") != nil else {
      throw CameraError(message: "Add NSMicrophoneUsageDescription to Info.plist before requesting microphone access.")
    }
  }
}
