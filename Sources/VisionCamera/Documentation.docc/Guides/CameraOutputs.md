# Camera outputs

Connect capture, streaming, scanning, and preview outputs to a Camera session.

``CameraOutput`` is the common protocol for outputs a ``CameraDevice`` can stream to using a ``CameraSession``.

VisionCamera provides six core output kinds:

- ``PhotoOutput``: <doc:PhotoOutputGuide>.
- ``VideoOutput``: <doc:VideoOutputGuide>.
- ``FrameOutput``: <doc:FrameOutputGuide>.
- ``DepthOutput``: <doc:DepthOutputGuide>.
- ``ObjectOutput``: <doc:ObjectOutputGuide>.
- ``PreviewOutput``: <doc:PreviewOutputGuide>.

In SwiftUI, pass retained outputs to ``Camera``. It connects its preview and adds output resolution preferences in order. See <doc:SwiftUICamera>.

## Connect outputs to a session

Add each output to the connection's outputs array:

```swift
import VisionCamera

func connectOutputs(session: CameraSession) async throws {
	let photo = PhotoOutput()
	let video = MovieFileVideoOutput()
	_ = try await session.configure([
		CameraSessionConnection(
			input: .position(.back),
			outputs: [.init(output: photo), .init(output: video)])
	])
}
```

Retain the output objects you intend to capture from or reconfigure later.

## Resolutions

Camera hardware provides a stream configured at a specific resolution. Each output specifies its own target resolution, either specified by the user or internally configured by VisionCamera.

When multiple outputs are connected, resolution-bias constraints express which target resolutions should influence the selected Camera stream format. Add these constraints explicitly. A target resolution is a preference, not a guarantee that every output receives those exact dimensions.

```swift
import CoreGraphics
import VisionCamera

func make4KOutputs() -> (PhotoOutput, any VideoOutput) {
	let resolution = CGSize(width: 3840, height: 2160)
	return (
		PhotoOutput(options: .init(targetResolution: resolution)),
		MovieFileVideoOutput(options: .init(targetResolution: resolution))
	)
}
```

See <doc:Constraints> to choose which output takes priority during negotiation.

## Output readiness

Often an output only becomes usable after it has been connected to the session. Await `configure(_:configuration:)` before querying connection-dependent capabilities or creating a recorder. Start the session before capturing live content.

Read `currentResolution` after configuration to inspect the result. Keep a ``CameraSessionConfig`` from the connection's `onSessionConfigSelected` callback to inspect selected constraints.

<!-- Adapted from react-native-vision-camera/docs/content/docs: camera-outputs. -->
