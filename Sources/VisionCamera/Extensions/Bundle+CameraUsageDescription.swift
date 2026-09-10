import Foundation

extension Bundle {
  func requireCameraUsageDescription() throws(PermissionError) {
    guard let description = object(forInfoDictionaryKey: "NSCameraUsageDescription") as? String,
      !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    else {
      throw PermissionError.missingUsageDescription(key: "NSCameraUsageDescription")
    }
  }

  func requireMicrophoneUsageDescription() throws(PermissionError) {
    guard let description = object(forInfoDictionaryKey: "NSMicrophoneUsageDescription") as? String,
      !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    else {
      throw PermissionError.missingUsageDescription(key: "NSMicrophoneUsageDescription")
    }
  }
}
