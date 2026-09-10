# The preview output

Stream a Camera feed into a native preview.

The ``PreviewOutput`` allows streaming a Camera feed into a preview, which may be connected to a ``PreviewView`` to display the Camera feed to the user.

## Create a preview output

```swift
import VisionCamera

@MainActor
func addPreview(session: CameraSession) async throws -> PreviewView {
	let output = PreviewOutput()
	let view = PreviewView(output: output)
	_ = try await session.configure([
		.init(input: .position(.back), outputs: [.init(output: output)])
	])
	await session.start()
	return view
}
```

Add the returned view to your UIKit hierarchy and size it with Auto Layout or a frame. See <doc:PreviewViewGuide>.

## Preview resolution

A ``PreviewOutput`` does not have a configurable target resolution. Since it can never display more pixels than the screen has, it prefers a Camera format at least as large as the screen.

This preference is only a small bias in resolution negotiation. A preview can be upscaled cheaply, whereas a recording's resolution cannot be recovered after capture. A resolution-bias constraint for a recording output takes priority over the preview's preference:

```swift
import VisionCamera

func preferRecordingResolution(video: any VideoOutput) -> [Constraint] {
	[.resolution(video)]
}
```

See <doc:Constraints> for resolution negotiation.

## Orientation

The preview follows the app's interface orientation. Setting `outputOrientation` on a preview output does not override that behavior. Photo, video, frame, and depth outputs can follow a separate orientation source. See <doc:Orientation>.

<!-- Adapted from react-native-vision-camera/docs/content/docs: preview-output. -->
