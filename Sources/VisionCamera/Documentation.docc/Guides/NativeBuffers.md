# Native buffers

Pass retained Camera buffers to other native image and video APIs.

A ``Frame`` wraps a native GPU-backed buffer. To interoperate with other libraries, it exposes its underlying `CMSampleBuffer` and `CVPixelBuffer` directly.

## Get a native buffer

Read ``Frame/pixelBuffer`` to retrieve a retained `CVPixelBuffer`, if the sample contains an image:

```swift
import CoreVideo
import VisionCamera

func nativeBuffer(frame: Frame) -> CVPixelBuffer? {
	return frame.pixelBuffer
}
```

The ``Frame/sampleBuffer`` property provides the `CMSampleBuffer` with its timing and attachments. A frame always retains a sample buffer; some native samples do not contain an image buffer.

## Retain a buffer while using it

Swift manages the lifetime of native Core Media and Core Video objects. Keep a strong reference while another operation uses a buffer, and release that reference when the operation finishes.

```swift
import CoreVideo
import VisionCamera

func retainPixels(from frame: Frame) -> CVPixelBuffer? {
	let pixelBuffer = frame.pixelBuffer
	return pixelBuffer
}
```

The returned buffer remains valid after the frame value goes out of scope. Copying a ``Frame`` or retaining its native buffer does not copy pixels. A separately retained buffer still occupies a buffer in the capture pool, so avoid keeping more buffers than your processing requires.

## Borrow CPU bytes

Native buffer ownership is different from borrowing a CPU pointer. `withUnsafeBytes` locks the pixel buffer and lends a read-only pointer only for the closure's duration. Never store that pointer or use it after the closure returns.

See <doc:FrameGuide> for packed and planar access. Pass a retained native buffer to GPU or media APIs that accept it, instead of copying its pixels through CPU memory.

## Depth and photo buffers

``Depth`` exposes its native `AVDepthData` through `depthData` and its depth map through `pixelBuffer`. ``Photo`` exposes `AVCapturePhoto` and an optional pixel buffer.

The same ownership rule applies: a separately retained native object remains valid until its own references are released.

<!-- Adapted from react-native-vision-camera/docs/content/docs: a-frames-nativebuffer. -->
