// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "VisionCamera",
  platforms: [.iOS("15.1")],
  products: [
    .library(name: "VisionCamera", targets: ["VisionCamera"])
  ],
  targets: [
    .target(name: "VisionCamera"),
    .testTarget(name: "VisionCameraTests", dependencies: ["VisionCamera"]),
  ],
  swiftLanguageModes: [.v5]
)
