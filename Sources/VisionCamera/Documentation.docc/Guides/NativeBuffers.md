# Native buffers

Pass retained Camera buffers to other native image and video APIs.

A ``Frame`` wraps a native GPU-backed buffer. To interoperate with other libraries, it exposes its underlying `CMSampleBuffer` and `CVPixelBuffer` directly.

## Get a native buffer

Use `getPixelBuffer()` to retrieve a retained `CVPixelBuffer`:

```swift
import CoreVideo
import VisionCamera

func nativeBuffer(frame: Frame) throws -> CVPixelBuffer {
	return try frame.getPixelBuffer()
}
```

The optional `sampleBuffer` property provides the `CMSampleBuffer` with its timing and attachments.

## Retain a buffer while using it

Swift manages the lifetime of native Core Media and Core Video objects. Keep a strong reference while another operation uses a buffer, and release that reference when the operation finishes.

```swift
import CoreVideo
import VisionCamera

func retainPixelsAndReleaseWrapper(frame: Frame) throws -> CVPixelBuffer {
	let pixelBuffer = try frame.getPixelBuffer()
	frame.dispose()
	return pixelBuffer
}
```

The returned buffer remains valid after the frame wrapper is disposed. There is no integer pointer handle or manual `release()` contract. A separately retained buffer still occupies a buffer in the capture pool, so avoid keeping more buffers than your processing requires.

## Borrow CPU bytes

Native buffer ownership is different from borrowing a CPU pointer. `withUnsafeBytes` locks the pixel buffer and lends a read-only pointer only for the closure's duration. Never store that pointer or use it after the closure returns.

See <doc:FrameGuide> for packed and planar access. Pass a retained native buffer to GPU or media APIs that accept it, instead of copying its pixels through CPU memory.

## Depth and photo buffers

``Depth`` exposes its native `AVDepthData` through `getDepthData()` and its depth map through `getPixelBuffer()`. ``Photo`` exposes `AVCapturePhoto` and an optional pixel buffer.

The same ownership rule applies: a separately retained native object remains valid until its own references are released.

<!-- Adapted from react-native-vision-camera/docs/content/docs: a-frames-nativebuffer. -->
