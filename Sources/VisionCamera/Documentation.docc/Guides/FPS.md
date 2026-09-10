# FPS

Adjust the frame rate used by preview, video, and frame outputs.

A Camera's frame rate is configured per ``CameraSessionConnection`` and affects preview, video, and frame outputs.

## Get available FPS ranges

Each ``CameraDevice`` lists the FPS ranges it supports individually via `supportedFrameRateRanges`. You can also check whether a fixed FPS value is individually supported:

```swift
import VisionCamera

func inspectFrameRates(device: CameraDevice) {
	print(device.supportedFrameRateRanges)
	print("Supports 60 FPS:", device.supports(frameRate: 60))
}
```

A device supporting a given FPS individually does not guarantee support with every feature and output combination. Session configuration negotiates the constraints together and can select a lower frame rate if needed.

## Set FPS

```swift
import VisionCamera

func configure60FPS(session: CameraSession, output: any CameraOutput) async throws {
	_ = try await session.configure([
		.init(
			input: .position(.back),
			outputs: [.init(output: output)],
			constraints: [.frameRate(60)])
	])
}
```

Fractional rates such as `29.97` keep their precision when converted to native frame durations. Zero, negative, and non-finite requests throw during negotiation.

Inspect ``CameraSessionConfig`` in `onSessionConfigSelected` to see the selected FPS. Constraint ordering controls whether FPS or another preference wins. See <doc:Constraints>.

<!-- Adapted from react-native-vision-camera/docs/content/docs: fps. -->
