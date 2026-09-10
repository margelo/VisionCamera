#!/bin/bash
set -euo pipefail

repository_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
test_package="$repository_root/build/barcode-host"
mkdir -p "$test_package/Sources" "$test_package/Tests"
cp "$repository_root/Tests/BarcodeHost/Package.swift" "$test_package/Package.swift"
ln -sfn "$repository_root/Sources/VisionCameraBarcodeScanner" "$test_package/Sources/VisionCameraBarcodeScanner"
ln -sfn "$repository_root/Tests/VisionCameraBarcodeScannerTests" "$test_package/Tests/VisionCameraBarcodeScannerTests"
swift test --package-path "$test_package"
