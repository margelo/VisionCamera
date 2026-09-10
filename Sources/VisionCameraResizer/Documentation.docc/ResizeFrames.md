# Resize camera frames

Process native frames on the camera output's serial callback queue.

## Configure the output

Create a resizer for your model's tensor dimensions and channel encoding.
Use a YUV `FrameOutput` to request full-range NV12 pixels.
Keep `discardsLateFrames` enabled to discard incoming frames when processing exceeds the frame budget.

```swift
import VisionCamera
import VisionCameraResizer

let resizer = try GPUResizer(
	options: ResizerOptions(
		width: 192,
		height: 192,
		dataType: .float32,
		pixelLayout: .planar
	)
)
let output = FrameOutput(options: FrameOutputOptions(pixelFormat: .pixelFormat(.yuv4208BitFull)))
await output.setFrameHandler { frame in
	do {
		let result = try resizer.resize(frame)
		result.withUnsafeBytes { bytes in
			let channels = bytes.bindMemory(to: Float.self)
			print(channels.count) // 192 * 192 * 3
		}
	} catch GPUResizerError.outputCapacityExceeded {
		// Drop this frame while downstream processing still owns every output buffer.
	} catch {
		print("Resize failed: \(error)")
	}
}
```

Connect `output` to your camera session alongside the outputs your app needs.
Use this resizer only from this output's callback queue.
The first call creates the Metal pipeline and can take longer than later calls.

## Read the tensor

Use ``GPUResizeResult/withUnsafeBytes(_:)`` for scoped CPU reads.
Use ``GPUResizeResult/withMetalBuffer(_:)`` to encode Metal reads without a CPU copy.
Read <doc:BufferOwnership> before retaining results or submitting asynchronous GPU commands.

## Stop processing

Remove the callback through `await output.setFrameHandler(nil)` when you no longer need frame processing.
The current synchronous resize completes before the serial queue applies the callback change.
The resizer does not schedule tasks, enqueue future frames, or provide cancellation of a command already committed to Metal.

Release the resizer and its results to free its GPU allocations.
