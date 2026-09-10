# VisionCamera

A native Swift camera framework for iOS with UIKit previews, photo capture, video recording, frame and depth outputs, and camera controls built on AVFoundation.

## Install with Swift Package Manager

VisionCamera requires Xcode 26 or later and supports iOS 15.1 or later. The package uses Swift 5 language mode and has no external dependencies.

1. In Xcode, choose **File > Add Package Dependencies**.
2. Enter `https://github.com/margelo/VisionCamera.git`.
3. Until the first release containing `Package.swift`, select the **Branch** dependency rule and enter `main`. The existing `0.1.0` tag does not include the package manifest.
4. Add the **VisionCamera** library product to your app target.

The repository is currently private. Authenticate with a GitHub account that has access.

For another Swift package, add the dependency and library product to your `Package.swift`:

```swift
dependencies: [
	.package(url: "https://github.com/margelo/VisionCamera.git", branch: "main")
],
targets: [
	.target(
		name: "YourApp",
		dependencies: [
			.product(name: "VisionCamera", package: "VisionCamera")
		]
	)
]
```

After the first SPM release, use a version requirement instead of `branch: "main"`. For a `0.1.1` release, use `.upToNextMinor(from: "0.1.1")` to receive compatible `0.1.x` updates. Use a released version containing `Package.swift` before publishing a package that depends on VisionCamera.

Add `NSCameraUsageDescription` to your app's `Info.plist`. If your app records audio, also add `NSMicrophoneUsageDescription`.

```swift
import VisionCamera

let camera = VisionCamera()
let authorized = try await camera.requestCameraPermission()
```

See [the example app](Example/Sources/CameraViewController.swift) for preview, photo, and recording setup.

## Build and test the package

Open `Package.swift` in Xcode, select the **VisionCamera** scheme and an iOS simulator, then choose **Product > Test**.

To build for iOS from the command line:

```sh
xcodebuild -scheme VisionCamera -configuration Release \
	-destination 'generic/platform=iOS' \
	-derivedDataPath build/spm-device CODE_SIGNING_ALLOWED=NO build
```

To run the existing tests, replace `<simulator-udid>` with an available iOS simulator identifier from `xcrun simctl list devices available`:

```sh
xcodebuild -scheme VisionCamera \
	-destination 'platform=iOS Simulator,id=<simulator-udid>' \
	-derivedDataPath build/spm-simulator CODE_SIGNING_ALLOWED=NO test
```

The framework imports UIKit and requires an iOS destination. `swift test` on the macOS host cannot build it.

For release instructions, see [Publishing](PUBLISHING.md).
