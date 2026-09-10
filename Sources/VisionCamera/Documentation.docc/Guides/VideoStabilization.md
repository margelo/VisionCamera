# Video stabilization

Reduce camera shake in recorded videos and previews.

Video stabilization applies software and sometimes hardware processing to stabilize frames in the Camera.

## Enable stabilization

Pass a ``VideoStabilizationModeConstraint`` with your desired ``TargetStabilizationMode``:

```swift
import VisionCamera

func configureStabilizedVideo(
	session: CameraSession,
	output: any CameraVideoOutput
) async throws {
	_ = try await session.configure(connections: [
		.init(
			input: .position(.back),
			outputs: [.init(output: output)],
			constraints: [
				.videoStabilizationMode(.init(videoStabilizationMode: .cinematic))
			]
		)
	])
}
```

Modes have different device and OS requirements. Inspect `CameraSessionConfig.selectedVideoStabilizationMode` to see the result of negotiation.

Use a ``PreviewStabilizationModeConstraint`` to express a preview stabilization preference. See <doc:Constraints> for how preferences are negotiated together.

## Latency and field of view

Software stabilization keeps a queue of frames in memory to smooth motion. This introduces latency, so frames arrive later than when they were captured. Stronger modes can also crop more of the image.

Choose a mode that suits the use case. A live interaction may need lower latency than a recorded video.

<!-- Adapted from react-native-vision-camera/docs/content/docs/video-stabilization.mdx. -->
