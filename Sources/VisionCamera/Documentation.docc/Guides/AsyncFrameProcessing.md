# Asynchronous frame processing

Move slow processing off the frame callback while keeping outstanding work bounded.

Frame callbacks run synchronously on the frame output's queue. If your processing cannot keep up with the Camera's frame rate, you can move that work to a separate queue.

## Process one frame at a time

The Camera has a small pool of reusable buffers. Scheduling every incoming frame on an unbounded queue can exhaust that pool. Accept a new frame only when the worker is free:

```swift
import Foundation
import VisionCamera

func installAsyncProcessor(
	on output: CameraFrameOutput,
	process: @escaping (Frame) throws -> Void
) async {
	let worker = DispatchQueue(label: "com.example.camera.processing")
	let availableSlot = DispatchSemaphore(value: 1)

	await output.setOnFrameCallback { frame in
		guard availableSlot.wait(timeout: .now()) == .success else {
			frame.dispose()
			return
		}

		worker.async(execute: DispatchWorkItem {
			defer {
				frame.dispose()
				availableSlot.signal()
			}
			do {
				try process(frame)
			} catch {
				print("Frame processing failed:", error)
			}
		})
	}
}
```

The semaphore is a nonblocking admission check shared by the callback queue and worker queue. If the worker is busy, the callback drops the incoming frame immediately. The worker retains one accepted frame until processing finishes, then releases the slot.

This pattern keeps the preview responsive while processing fewer frames. It does not make the processing itself faster.

## Finish before releasing the frame

The `process` closure must finish using the frame before it returns. If another native API completes asynchronously, keep the frame until its completion callback and release the processing slot there instead.

Do not dispose a frame while another operation is reading it. Do not keep borrowed pointers from `withUnsafeBytes` after the closure returns. See <doc:NativeBuffers>.

## Remove the callback

Call `await output.setOnFrameCallback(nil)` to stop accepting frames. Removing the callback does not cancel work already running on your worker queue. Let that work finish and release its retained frame.

For processing that fits within the frame budget, staying in the original callback avoids this additional queue. See <doc:NativeProcessing>.

<!-- Adapted from react-native-vision-camera/docs/content/docs: async-frame-processing. -->
