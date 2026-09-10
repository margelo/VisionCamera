# The frame output

Stream camera frames to a Swift callback in real time.

The ``FrameOutput`` streams ``Frame`` objects in real time, making their native buffers available to your processing code.

## Create a frame output

Create an output, register its callback, and connect it to a session:

```swift
import VisionCamera

func prepareFrameCamera() async throws -> (CameraSession, FrameOutput) {
	let session = CameraSession()
	let output = FrameOutput(options: .init(pixelFormat: .pixelFormat(.yuv4208BitFull)))
	await output.setFrameHandler { frame in
		print("Frame:", frame.width as Any, frame.height as Any, frame.timestamp)
	}
	_ = try await session.configure([
		.init(input: .position(.back), outputs: [.init(output: output)])
	])
	await session.start()
	return (session, output)
}
```

The callback runs synchronously on the frame output's queue. Keep work within the frame budget, and dispatch only UI updates to the main queue. Clear the callback with `await output.setFrameHandler(nil)` when you no longer need frames.

See ``FrameOutputOptions`` for configuration options.

## Release frames promptly

A frame is a GPU-backed buffer streamed at full resolution and frame rate. The Camera pipeline keeps a small pool of reusable buffers. Retaining every frame exhausts that pool and causes subsequent frames to be dropped.

Swift releases the native buffer when no frame values or native references retain it. For synchronous processing, letting the callback return without retaining the frame is sufficient.

If processing continues after the callback returns, keep the frame alive until that work finishes and bound the number of outstanding frames. See <doc:AsyncFrameProcessing>.

## Choose a pixel format

Choose the format your processing code can consume directly. `.native` uses the format negotiated by the Camera. `.pixelFormat(.yuv4208BitFull)` requests full-range 8-bit YUV buffers. `.pixelFormat(.rgbBgra8Bit)` requests BGRA buffers.

RGB is familiar, but often requires conversion and uses about 2.6 times the bandwidth of 8-bit YUV 4:2:0. If your processing supports YUV, avoid converting just to access pixels.

Inspect each frame's `pixelFormat` to understand its actual layout. A native format may use a layout that your CPU processing does not support. See <doc:PixelFormats> and <doc:FrameGuide>.

## Drop late frames

`discardsLateFrames` defaults to `true`. Frames that arrive while your callback is still running can be dropped to keep latency bounded. Disabling this option can increase buffering and memory use when processing is too slow.

For expensive processing, see <doc:NativeProcessing> and <doc:AsyncFrameProcessing>.

<!-- Adapted from react-native-vision-camera/docs/content/docs/frame-output.mdx. -->
