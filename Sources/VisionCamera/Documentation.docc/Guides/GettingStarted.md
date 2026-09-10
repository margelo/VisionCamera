# Getting started

Install VisionCamera, request Camera permission, and render a Camera preview in your app.

## Introduction

VisionCamera is a Camera framework for iOS. It uses AVFoundation and provides an extensible API, allowing you to plug in native code at any point.

The framework supports iOS 15.1 and later. Individual Camera features depend on the device and OS version.

## Install the library

### Swift Package Manager

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

## Render a Camera preview

Create a ``CameraSession``, connect a ``CameraPreviewOutput``, and display it in a ``PreviewView``:

```swift
import UIKit
import VisionCamera

@MainActor
func startCamera(in container: UIView) async throws -> CameraSession {
	let camera = VisionCamera()
	guard try await camera.requestCameraPermission() else {
		throw CameraError(message: "Camera access was not granted.")
	}

	let session = try camera.createCameraSession()
	let output = camera.createPreviewOutput()
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

> Note: The bundled UIKit example demonstrates preview, photo capture, video recording, gestures, and screen lifecycle with a local development Pod.

## Add outputs

The Camera can stream to a variety of outputs. To capture Photos, add a ``CameraPhotoOutput`` to the same connection. To record Videos, add a ``CameraVideoOutput``.

See <doc:CameraOutputs> to learn more about outputs.

<!-- Adapted from react-native-vision-camera/docs/content/docs: index. -->
