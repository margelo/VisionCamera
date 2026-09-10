# Getting started

Install VisionCamera, request Camera permission, and render a Camera preview in your app.

## Introduction

VisionCamera is a Camera framework for iOS. It uses AVFoundation and provides an extensible API, allowing you to plug in native code at any point.

The framework supports iOS 15.1 and later. Start with SwiftUI and Swift Package Manager. UIKit and CocoaPods are equally functional, actively maintained alternatives. Individual Camera features depend on the device and OS version.

## Install the library

### Swift Package Manager (recommended)

Use Xcode 26.2 or later. The package uses Swift 5 language mode.

In Xcode, choose **File > Add Package Dependencies** and enter the repository URL:

```text
https://github.com/margelo/VisionCamera.git
```

Select the `main` branch and add the `VisionCamera` product to your app target. These guides describe the API on `main`. The initial `0.1.0` tag predates the package manifest and some API changes. Pin a release containing the current API when one is available.

The repository is private, so Xcode needs a GitHub account with access. If your setup uses SSH authentication, use `ssh://git@github.com/margelo/VisionCamera.git`.

### CocoaPods

Add VisionCamera to your app's Podfile:

```ruby
platform :ios, '15.1'
use_frameworks! :linkage => :static

target 'YourApp' do
	pod 'VisionCamera', :git => 'https://github.com/margelo/VisionCamera.git', :branch => 'main'
end
```

For a local checkout, replace the Pod declaration with `pod 'VisionCamera', :path => '../VisionCamera'`.

Run `pod install`, then open the generated `.xcworkspace`. Git-based installation requires access to the private repository. Pin a commit or an appropriate release tag when integrating the library into your app.

## Add permissions

Add `NSCameraUsageDescription`, and optionally `NSMicrophoneUsageDescription`, to your app's `Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Use the camera to capture photos and videos.</string>
<key>NSMicrophoneUsageDescription</key>
<string>Record audio for videos.</string>
```

## Mount a SwiftUI Camera

Request permission with ``VisionCamera/requestCameraPermission()`` and select a device with ``VisionCamera/getDefaultCamera(position:)``. Mount a ``Camera`` after permission is granted:

```swift
import SwiftUI
import VisionCamera

struct CameraScreen: View {
	@Environment(\.scenePhase) private var scenePhase
	@State private var device: CameraDevice?
	@State private var message = "Requesting Camera access..."

	var body: some View {
		Group {
			if let device {
				Camera(device: device, isActive: scenePhase == .active)
					.enableZoomGesture()
					.enableTapToFocusGesture()
			} else {
				Text(message)
			}
		}
		.task {
			do {
				guard try await VisionCamera.requestCameraPermission() else {
					message = "Camera access was denied. Enable it in Settings."
					return
				}
				device = VisionCamera.getDefaultCamera(position: .back)
				if device == nil { message = "No Camera is available." }
			} catch {
				message = error.localizedDescription
			}
		}
	}
}
```

``Camera`` owns the session and preview for its mounted lifetime. It configures the session before starting and stops capture when removed. If navigation keeps the Camera mounted while hidden, include screen visibility in `isActive`. See <doc:SwiftUICamera> and <doc:Lifecycle>.

Open `ExampleSwiftUI/VisionCameraSwiftUIExample.xcodeproj` for a runnable SwiftUI app using the local Swift package. Choose an iPhone destination and run. Camera capture requires a physical device.

## Use UIKit

Request permission with ``VisionCamera/requestCameraPermission()``. Create a ``CameraSession``, connect a ``PreviewOutput``, and display it in a ``PreviewView``:

```swift
import UIKit
import VisionCamera

@MainActor
func startCamera(in container: UIView) async throws -> CameraSession {
	guard try await VisionCamera.requestCameraPermission() else {
		throw CameraError(message: "Camera access was not granted.")
	}

	let session = CameraSession()
	let output = PreviewOutput()
	let preview = PreviewView(previewOutput: output)
	preview.frame = container.bounds
	preview.autoresizingMask = [.flexibleWidth, .flexibleHeight]
	container.addSubview(preview)

	_ = try await session.configure(connections: [
		CameraSessionConnection(
			input: .position(.back),
			outputs: [CameraOutputConfiguration(output: output)])
	])
	await session.start()
	return session
}
```

Retain the returned session for as long as your Camera screen needs it. Stop the session when the screen goes out of view. See <doc:Lifecycle>.

The UIKit example in `Example` uses a local development Pod. Run `bundle exec pod install` in that directory and open `VisionCameraExample.xcworkspace`.

## Add outputs

The Camera can stream to a variety of outputs. To capture Photos, pass a retained ``PhotoOutput`` to the SwiftUI Camera's `outputs` array or add it to a native session connection. To record Videos, use a ``MovieFileVideoOutput`` or ``VideoFrameOutput``. Keep outputs in a model owned by `@StateObject`, so view updates reuse the same native objects.

See <doc:CameraOutputs> to learn more about outputs.

<!-- Adapted from react-native-vision-camera/docs/content/docs: index. -->
