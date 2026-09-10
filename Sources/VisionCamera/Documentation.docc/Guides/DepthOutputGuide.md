# The depth output

Stream depth frames from a supported Camera device.

The ``DepthOutput`` streams ``Depth`` frames in real time to a Swift callback.

## Create a depth output

Depth requires a device and active format that support depth delivery. Create an output and connect it to your selected device:

```swift
import VisionCamera

func prepareDepthCamera(device: CameraDevice) async throws -> (CameraSession, DepthOutput) {
	let session = CameraSession()
	let output = DepthOutput(options: .init(isFilteringEnabled: true))
	await output.setDepthHandler { depth in
		print("Depth:", depth.width, depth.height, depth.pixelFormat)
	}
	_ = try await session.configure([
		.init(input: .device(device), outputs: [.init(output: output)])
	])
	await session.start()
	return (session, output)
}
```

Configuration throws if no compatible device format is available. See ``DepthOutputOptions`` for target resolution, filtering, and buffer rotation settings.

The callback runs on the depth output's queue. Clear it with `await output.setDepthHandler(nil)` when you no longer need depth delivery.

## Release depth frames promptly

Depth buffers use a small pool of reusable buffers. Retaining too many depth frames prevents the Camera from reusing the pool and causes drops.

Let the depth value go out of scope after your callback finishes. If you retain depth data for asynchronous work, keep it only until that work finishes and bound the outstanding work.

See <doc:DepthFrame> for interpreting depth data and <doc:AsyncFrameProcessing> for managing asynchronous processing.

<!-- Adapted from react-native-vision-camera/docs/content/docs/depth-output.mdx. -->
