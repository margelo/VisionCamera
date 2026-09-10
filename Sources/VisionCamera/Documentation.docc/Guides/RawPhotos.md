# Capturing RAW photos

Capture RAW photos in Adobe DNG containers.

A typical photo pipeline contains multiple processing stages in the image signal processor: white balancing, color interpolation and correction, color space conversions, and finally JPEG or HEIF compression.

RAW capture preserves sensor image data for later processing. RAW photos are captured in DNG format, represented by `.dng` in ``PhotoContainerFormat``.

## Prepare the pipeline for RAW

Configure your ``PhotoOutput`` with a `.dng` container format:

```swift
import VisionCamera

func prepareRAWCamera(device: CameraDevice) async throws -> (CameraSession, PhotoOutput) {
	let session = CameraSession()
	let output = PhotoOutput(options: .init(
		containerFormat: .dng,
		previewImageTargetSize: .init(width: 320, height: 320)
	))
	_ = try await session.configure(connections: [
		.init(input: .device(device), outputs: [.init(output: output)])
	])
	await session.start()
	return (session, output)
}
```

RAW support depends on the selected device and configuration. Handle configuration and capture errors when RAW is unavailable.

Since RAW capture uses more bandwidth, a capture can take longer. Request a preview image to display as a thumbnail when available. See <doc:PhotoCallbacks>.

## Capture RAW

Capture using the same method as a processed photo:

```swift
import Foundation
import VisionCamera

func captureRAW(output: PhotoOutput) async throws -> URL {
	let photo = try await output.capturePhoto()
	let path = try await photo.saveToTemporaryFileAsync()
	return URL(fileURLWithPath: path)
}
```

When the output is configured for DNG, the saved file has a `.dng` extension. Access available RAW pixels through the photo's `pixelBuffer`, or read encoded DNG data through `getFileDataAsync()`.

## Apple ProRAW

On supported devices and configurations, the photo output enables Apple ProRAW and selects its RAW format. ProRAW includes computational photography processing, so its processing differs from conventional sensor RAW.

Use a RAW-capable image pipeline to develop either format. `Photo.toImageAsync()` does not develop RAW photos.

<!-- Adapted from react-native-vision-camera/docs/content/docs/raw-photos.mdx. -->
