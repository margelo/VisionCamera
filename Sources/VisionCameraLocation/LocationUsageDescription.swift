import Foundation

enum LocationUsageDescription {
  static func validate(in bundle: Bundle) throws {
    try validate(bundle.object(forInfoDictionaryKey: "NSLocationWhenInUseUsageDescription"))
  }

  static func validate(_ value: Any?) throws {
    guard let description = value as? String,
      !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    else {
      throw LocationManagerError.missingUsageDescription
    }
  }
}
