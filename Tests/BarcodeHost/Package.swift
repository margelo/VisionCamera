// swift-tools-version: 6.2

import PackageDescription

// This is a validation package only. The published package remains iOS-only.
let package = Package(
  name: "VisionCameraBarcodeHostTests",
  platforms: [.macOS(.v14)],
  targets: [
    .target(
      name: "VisionCameraBarcodeScanner",
      exclude: ["BarcodeScanner+Frame.swift", "BarcodeScanner+UIImage.swift", "BarcodeImageGeometry+UIImageOrientation.swift", "Documentation.docc"]),
    .testTarget(
      name: "VisionCameraBarcodeScannerTests",
      dependencies: ["VisionCameraBarcodeScanner"],
      exclude: ["BarcodeScannerAdapterTests.swift", "BarcodeUIImageGeometryTests.swift"]),
  ],
  swiftLanguageModes: [.v5])
