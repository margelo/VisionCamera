# Video HDR

Capture video with a higher dynamic range and 10-bit encoding.

Video HDR captures frames in a higher dynamic range, preserving more detail in highlights and shadows.

## Enable video HDR

Pass a ``VideoDynamicRangeConstraint`` in your connection's constraints. For example, request 10-bit HLG with BT.2020 color primaries:

```swift
import VisionCamera

func configureHDR(
	session: CameraSession,
	device: CameraDevice,
	output: any CameraVideoOutput
) async throws {
	let dynamicRange = TargetDynamicRange(
		bitDepth: .hdr10Bit,
		colorSpace: .hlgBt2020,
		colorRange: .video
	)
	_ = try await session.configure(connections: [
		.init(
			input: .device(device),
			outputs: [.init(output: output)],
			constraints: [.videoDynamicRange(.init(videoDynamicRange: dynamicRange))],
			onSessionConfigSelected: { config in
				print("Selected dynamic range:", config.selectedVideoDynamicRange as Any)
			}
		)
	])
}
```

The session negotiates the dynamic range with your other constraints and connected outputs. Constraints are ordered preferences. Inspect the selected configuration to see whether the requested dynamic range was chosen. See <doc:Constraints>.

For a custom dynamic range, choose a different ``TargetColorSpace``, such as `.appleLog` on supported hardware and OS versions. A requested color space is not a guarantee that the device supports it.

## Bit depth

Higher bit depth provides more sample levels for each channel. An 8-bit channel has 256 levels and a 10-bit channel has 1,024. Bit depth alone does not determine a display's maximum brightness.

## Transfer functions and color spaces

A transfer function describes how encoded values relate to brightness. HDR video commonly uses HLG or PQ transfer functions. Wider color primaries such as BT.2020 also allow a broader range of colors than an SDR sRGB pipeline.

These choices affect capture, encoding, processing, and display. Keep the color metadata when passing captured buffers to another image or video pipeline.

## Extended dynamic range

Some capture pipelines combine multiple exposures to retain highlight and shadow detail. The processing depends on the device, selected format, and frame rate. Video HDR configuration is separate from <doc:PhotoHDR>.

<!-- Adapted from react-native-vision-camera/docs/content/docs/video-hdr.mdx. -->
