# A frame

Understand frame metadata, pixel layouts, and buffer lifetime.

A ``Frame`` is an in-memory buffer that allows GPU and CPU access to individual pixels. It is typically streamed in real time by a ``CameraFrameOutput``.

See <doc:FrameOutput> for streaming frames, and <doc:NativeProcessing> for passing them to native image processing APIs.

## Orientation and mirroring

A frame's `orientation` describes the rotation needed for its intended presentation. Similarly, `isMirrored` describes whether the consumer should mirror it.

Consider both values as instructions for presenting the frame. By default, the Camera passes orientation and mirroring as metadata so consumers can apply the transform when processing or rendering. Physically transforming every buffer requires additional work.

If you need transformed buffers, enable `FrameOutputOptions.enablePhysicalBufferRotation`. The resulting frame reports `.up` and `false`, indicating no further rotation or mirroring is needed. See <doc:Orientation>.

## Pixel formats

The frame's `pixelFormat` describes its pixel layout. The familiar BGRA format uses four 8-bit components per pixel, but the Camera commonly produces a YUV format.

YUV 4:2:0 uses less memory than BGRA and can avoid a conversion. The right format depends on what your processing API accepts. See <doc:PixelFormats>.

## Access packed pixels

For a nonplanar buffer, `withUnsafeBytes` provides scoped, read-only CPU access:

```swift
import Foundation
import VisionCamera

func copyPackedPixels(frame: Frame) throws -> Data {
	return try frame.withUnsafeBytes { bytes in
		Data(bytes)
	}
}
```

The method locks the native pixel buffer for the duration of the closure and unlocks it afterward, including when the closure throws.

> Important: Do not return or store the borrowed pointer. It is valid only inside the closure. Copy bytes into `Data` if you need an independently owned CPU buffer.

A row may contain padding. Use `bytesPerRow`, the frame dimensions, and the pixel format when interpreting its contents.

## Planar frames

Some frames store their pixels in multiple planes. On iOS, YUV 4:2:0 commonly uses one plane for Y and one for interleaved CbCr.

Use `getPlanes()` to access each ``FramePlane``:

```swift
import Foundation
import VisionCamera

func copyPlanes(frame: Frame) throws -> [Data] {
	return try frame.getPlanes().map { plane in
		try plane.withUnsafeBytes { bytes in Data(bytes) }
	}
}
```

For a nonplanar frame, `getPlanes()` returns an empty array. Each plane has its own dimensions and row stride. A plane retains its native pixel buffer independently of the frame wrapper.

## Frame lifetime

A 4K BGRA frame is roughly 33 MB, so streaming at 60 FPS moves about 2 GB of image data per second. The capture pipeline reuses buffers to avoid allocating that memory for every frame.

Release frames as soon as processing finishes. Swift's automatic reference counting handles this when no references remain. `dispose()` releases the frame wrapper's sample buffer earlier and makes `isValid` return `false`.

Native buffers and ``FramePlane`` objects you retained separately remain valid after the wrapper is disposed. They also keep the capture buffer in use. See <doc:NativeBuffers>.

<!-- Adapted from react-native-vision-camera/docs/content/docs/a-frame.mdx. -->
