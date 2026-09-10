# Photo output callbacks

Observe capture stages and receive preview images.

The photo capture pipeline has multiple stages. Each stage invokes the respective callback in ``CapturePhotoCallbacks``.

## Capture events

A photo capture exposes three stage callbacks:

1. `willBeginCapture`
2. `willCapturePhoto`
3. `didCapturePhoto`

Pass callbacks to `capturePhoto(settings:callbacks:)`:

```swift
import VisionCamera

func captureWithEvents(output: PhotoOutput) async throws -> Photo {
	return try await output.capturePhoto(callbacks: .init(
		willBeginCapture: { print("Capture beginning") },
		willCapturePhoto: { print("Capturing photo") },
		didCapturePhoto: { print("Photo captured") }
	))
}
```

These callbacks run on the photo output's queue. Dispatch UIKit changes to the main queue. The capture method returns the photo after processing succeeds, or throws if capture fails.

## Preview images

A ``PhotoOutput`` can deliver a preview-sized image for a thumbnail, assuming the device and capture configuration support it.

First, specify `previewImageTargetSize` when creating the output:

```swift
import VisionCamera

func makePhotoOutput() -> PhotoOutput {
	return PhotoOutput(options: .init(
		previewImageTargetSize: .init(width: 320, height: 320)
	))
}
```

Then pass an `didReceivePreviewImage` callback when capturing:

```swift
import UIKit
import VisionCamera

@MainActor
func captureWithThumbnail(
	output: PhotoOutput,
	imageView: UIImageView
) async throws -> Photo {
	return try await output.capturePhoto(callbacks: .init(
		didReceivePreviewImage: { image in
			DispatchQueue.main.async {
				imageView.image = image
			}
		}
	))
}
```

The preview callback is delivered when the processed capture makes a preview image available. Do not depend on it arriving substantially before the final photo. If the capture has no preview image, the callback is not called.

<!-- Adapted from react-native-vision-camera/docs/content/docs/photo-output-callbacks.mdx. -->
