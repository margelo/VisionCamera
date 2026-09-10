# Video stabilization

Reduce camera shake in recorded videos and previews.

Video stabilization applies software and sometimes hardware processing to stabilize frames in the Camera.

## Enable stabilization

Pass a ``Constraint/videoStabilization(_:)`` with your desired ``TargetStabilizationMode``:

```swift
import VisionCamera

func configureStabilizedVideo(
	session: CameraSession,
	output: any VideoOutput
) async throws {
	_ = try await session.configure([
		.init(
			input: .position(.back),
			outputs: [.init(output: output)],
			constraints: [
				.videoStabilization(.cinematic)
			]
		)
	])
}
```

Modes have different device and OS requirements. Negotiation checks each native mode before falling back and reports the mode it can configure. If no stabilization mode is supported, it selects `.off`. Inspect `CameraSessionConfig.selectedVideoStabilizationMode` to see the result of negotiation.

Use a ``Constraint/previewStabilization(_:)`` to express a preview stabilization preference. See <doc:Constraints> for how preferences are negotiated together.

## Latency and field of view

Software stabilization keeps a queue of frames in memory to smooth motion. This introduces latency, so frames arrive later than when they were captured. Stronger modes can also crop more of the image.

Choose a mode that suits the use case. A live interaction may need lower latency than a recorded video.

<!-- Adapted from react-native-vision-camera/docs/content/docs/video-stabilization.mdx. -->
