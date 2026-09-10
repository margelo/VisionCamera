# The photo output

Capture processed and RAW photos using a photo output.

The ``PhotoOutput`` allows capturing processed and RAW ``Photo`` objects.

## Create a photo output

Create an output, connect it to a ``CameraSession``, and start the session before capturing:

```swift
import VisionCamera

func preparePhotoCamera() async throws -> (CameraSession, PhotoOutput) {
	let session = CameraSession()
	let output = PhotoOutput()
	_ = try await session.configure(connections: [
		.init(input: .position(.back), outputs: [.init(output: output)])
	])
	await session.start()
	return (session, output)
}
```

Request Camera permission before calling this function. Retain the session and output while using the Camera. See <doc:GettingStarted> for permission setup, and ``PhotoOutputOptions`` for output configuration options.

## Capture a photo in memory

Use `capturePhoto(settings:callbacks:)` to capture an in-memory ``Photo``:

```swift
import VisionCamera

func takePhoto(output: PhotoOutput) async throws -> Photo {
	return try await output.capturePhoto(settings: .init(flashMode: .off))
}
```

See <doc:PhotoGuide> to understand the captured buffer, display it, or access its encoded data.

## Capture a photo to a file

Use `capturePhotoToFile(settings:callbacks:)` to capture a photo and save it to a temporary file:

```swift
import Foundation
import VisionCamera

func takePhotoFile(output: PhotoOutput) async throws -> URL {
	let photo = try await output.capturePhotoToFile()
	return URL(fileURLWithPath: photo.filePath)
}
```

`filePath` is a plain filesystem path. Use `URL(fileURLWithPath:)` when an API expects a URL.

See ``CapturePhotoSettings`` for capture options and <doc:PhotoCallbacks> for capture events.


## Select a photo format

The default `.automatic()` format selects HEIC when the connected output supports it and falls back to JPEG. Use `.jpeg(quality:)` or `.heic(quality:)` for an explicit processed format, or `.dng` for RAW. Unsupported explicit formats throw. See <doc:PhotoQuality> and <doc:RawPhotos>.

## Include depth data

Enable depth delivery before configuring the session, then request it for each photo that needs depth:

```swift
import VisionCamera

func makeDepthPhotoOutput() -> PhotoOutput {
	PhotoOutput(options: .init(enableDepthDataDelivery: true))
}

func captureDepthPhoto(output: PhotoOutput) async throws -> Photo {
	try await output.capturePhoto(settings: .init(enableDepthData: true))
}
```

Depth requires a compatible device, format, and processed photo container. Session configuration throws when depth delivery is unsupported. Per-capture options such as flash, shutter-sound suppression, distortion correction, and virtual device fusion also throw when explicitly requested but unsupported. Unspecified capture settings retain AVFoundation defaults.

<!-- Adapted from react-native-vision-camera/docs/content/docs/photo-output.mdx. -->
