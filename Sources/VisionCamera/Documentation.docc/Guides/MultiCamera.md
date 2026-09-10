# Multi-camera

Stream from multiple Camera devices in a single session.

A ``CameraSession`` allows attaching multiple connections to stream from multiple ``CameraDevice`` instances at the same time, for example a front-and-back picture-in-picture preview, if the system supports it.

## Create a multi-camera session

Check `supportsMultiCamSessions` before creating a multi-camera session:

```swift
import VisionCamera

func makeMultiCameraSession() throws -> CameraSession? {
	guard VisionCamera.supportsMultiCamSessions else { return nil }
	return try CameraSession(enableMultiCam: true)
}
```

## Find compatible devices

Due to hardware constraints, not every Camera can be paired with every other Camera. ``VisionCamera/supportedMultiCamDeviceCombinations`` exposes supported device combinations upfront:

```swift
import VisionCamera

func findCameraPair() -> [CameraDevice]? {
	VisionCamera.supportedMultiCamDeviceCombinations.first { $0.count >= 2 }
}
```

A combination contains one or more logical Camera devices. A combination can contain a single virtual Camera because that Camera is backed by multiple physical Cameras. Pass the returned Cameras directly to configuration, and use `physicalDevices` only for inspection. If you need multiple independent previews, choose a combination with at least two Cameras.

## Use multiple connections

Knowing two devices can be used simultaneously, create separate outputs and build the connections:

```swift
import VisionCamera

@MainActor
func configurePair(
	session: CameraSession,
	first: CameraDevice,
	second: CameraDevice
) async throws -> (PreviewView, PreviewView) {
	let firstOutput = PreviewOutput()
	let secondOutput = PreviewOutput()
	_ = try await session.configure(connections: [
		.init(input: .device(first), outputs: [.init(output: firstOutput)]),
		.init(input: .device(second), outputs: [.init(output: secondOutput)])
	])
	await session.start()
	return (PreviewView(previewOutput: firstOutput), PreviewView(previewOutput: secondOutput))
}
```

Each returned ``CameraController`` corresponds to the connection at that index. The first controller adjusts the first Camera's zoom, exposure, and focus.

## Picture-in-picture previews

Display each preview output in a separate ``PreviewView``. Lay out one view as the background and the other as an inset. Each preview output owns one native preview layer, so use a distinct output for each independently positioned preview.

Multiple Cameras use more bandwidth and thermal capacity. Configuration can fail when the requested combination or output requirements exceed the device's capabilities.

<!-- Adapted from react-native-vision-camera/docs/content/docs: multi-camera. -->
