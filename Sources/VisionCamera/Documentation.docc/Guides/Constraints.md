# Constraints

Express preferences for resolution, frame rate, dynamic range, and stabilization.

A ``CameraDevice`` can capture in different resolutions, frame rates, dynamic ranges, and output formats. Often such features have limitations. While 4K and 60 FPS might be supported individually, they may not be supported together due to bandwidth limitations.

VisionCamera internally negotiates constraints, allowing you to express intent and find the closest compatible solution.

## Array order is constraint priority

A ``Constraint`` listed higher up in the array has higher priority than one listed further down. If you prefer a closer frame-rate match over a closer resolution match, list FPS first:

```swift
import VisionCamera

func preferFrameRate(video: any VideoOutput) -> [Constraint] {
	[
		.frameRate(60),
		.resolution(video)
	]
}
```

Pass the result to ``CameraSessionConnection`` when configuring the session.

## Preferences can fall back

Constraints find the closest supported match. For example, an FPS preference of 99,999 requests the closest available frame rate instead of requiring that exact value.

This does not guarantee that every session can start. Missing permission, unavailable devices, incompatible outputs, and unsupported RAW capture can still fail. Handle configuration errors.

## Inspect selected constraints

When the session finds a compatible configuration, the connection's `onSessionConfigSelected` callback receives a populated ``CameraSessionConfig``:

```swift
import VisionCamera

func makeConnection(output: any CameraOutput) -> CameraSessionConnection {
	CameraSessionConnection(
		input: .position(.back),
		outputs: [.init(output: output)],
		constraints: [.frameRate(60)],
		onSessionConfigSelected: { config in
			print(config.selectedFPS as Any, config.nativePixelFormat, config.isBinned)
		})
}
```

The selected configuration describes negotiation. The callback does not mean that live capture has already started.

## Include output resolution preferences

The resolver does not automatically add a resolution-bias constraint for every output. To consider each output's target resolution, append those preferences after your explicit constraints:

```swift
import VisionCamera

func constraintsForOutputs(_ outputs: [any CameraOutput]) -> [Constraint] {
	let explicitConstraints: [Constraint] = [.frameRate(30)]
	let resolutionPreferences = outputs.map { output in
		Constraint.resolution(output)
	}
	return explicitConstraints + resolutionPreferences
}
```

The explicit constraints keep higher priority. Order the output preferences according to the importance of their target resolutions.

## Resolve constraints before starting

```swift
import VisionCamera

func resolveVideoConfiguration(device: CameraDevice, video: any VideoOutput) async throws -> CameraSessionConfig {
	try await VisionCamera.resolve(
		[.frameRate(30), .resolution(video)],
		for: device,
		outputs: [.init(output: video)])
}
```

## Common examples

If photo capture is more important than video capture, list its resolution bias first:

```swift
import VisionCamera

func preferPhotos(photo: PhotoOutput, video: any VideoOutput) -> [Constraint] {
	[
		.resolution(photo),
		.resolution(video),
		.frameRate(30)
	]
}
```

To stream frames at a lower resolution, set the frame output's target resolution to a lower `CGSize` and give it a resolution-bias constraint. Closest-match negotiation goes both ways.

For dynamic range and stabilization, see <doc:VideoHDR> and <doc:VideoStabilization>.

## Binned preference

Binned formats combine multiple neighboring sensor pixels into one larger effective pixel. This usually improves low-light sensitivity and reduces noise, but can trade away fine detail compared to a full-resolution non-binned readout. Binned formats also use less bandwidth.

Use `.binned(true)` to prefer a binned format, or `false` to prefer a non-binned format. Omitting the constraint means no preference.

> Note: ``Constraint/photoHDR(_:)`` is retained in the type model, but it does not enable or disable Photo HDR on iOS. See <doc:PhotoHDR>.

<!-- Adapted from react-native-vision-camera/docs/content/docs: constraints. -->
