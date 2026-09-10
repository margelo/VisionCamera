// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "VisionCamera",
  platforms: [.iOS("15.1")],
  products: [
    .library(name: "VisionCamera", targets: ["VisionCamera"]),
    .library(name: "VisionCameraResizer", targets: ["VisionCameraResizer"]),
    .library(name: "VisionCameraBarcodeScanner", targets: ["VisionCameraBarcodeScanner"]),
    .library(name: "VisionCameraLocation", targets: ["VisionCameraLocation"]),
  ],
  targets: [
    .target(name: "VisionCamera"),
    .target(name: "VisionCameraResizer", dependencies: ["VisionCamera"], resources: [.process("Shaders")]),
    .target(name: "VisionCameraBarcodeScanner", dependencies: ["VisionCamera"]),
    .target(name: "VisionCameraLocation"),
    .testTarget(name: "VisionCameraTests", dependencies: ["VisionCamera"]),
    .testTarget(name: "VisionCameraResizerTests", dependencies: ["VisionCameraResizer"]),
    .testTarget(name: "VisionCameraBarcodeScannerTests", dependencies: ["VisionCameraBarcodeScanner"]),
    .testTarget(name: "VisionCameraLocationTests", dependencies: ["VisionCameraLocation"]),
  ],
  swiftLanguageModes: [.v5]
)
