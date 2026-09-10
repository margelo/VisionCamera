# Pixel formats

Choose a frame format and map it to its native Core Video layout.

A frame's ``PixelFormat`` describes how pixels are stored in its native buffer. Choose a target format that your processing can consume directly.

## Request a format

``FrameOutputOptions`` offers three ``TargetVideoPixelFormat`` choices:

- `.native` uses the negotiated Camera format without requesting a conversion.
- `.yuv` requests YUV buffers, which usually avoid a costly color conversion.
- `.rgb` requests BGRA buffers, which often require conversion and use more memory.

Use YUV when your CPU processing supports it. Use the native format when your downstream pipeline accepts the negotiated buffer directly. Request RGB when your consumer requires it.

The native format may use a layout your processing does not support. Inspect the actual frame format before interpreting CPU bytes.

## Inspect a format

A received ``Frame`` exposes its precise `pixelFormat`. These common formats map to Core Video constants:

| VisionCamera format | Core Video format |
| --- | --- |
| `.yuv4208BitFull` | `kCVPixelFormatType_420YpCbCr8BiPlanarFullRange` |
| `.yuv4208BitVideo` | `kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange` |
| `.yuv42010BitFull` | `kCVPixelFormatType_420YpCbCr10BiPlanarFullRange` |
| `.yuv42010BitVideo` | `kCVPixelFormatType_420YpCbCr10BiPlanarVideoRange` |
| `.rgbBgra8Bit` | `kCVPixelFormatType_32BGRA` |
| `.depth16Bit` | `kCVPixelFormatType_DepthFloat16` |
| `.depth32Bit` | `kCVPixelFormatType_DepthFloat32` |

The native buffer also exposes its `OSType` directly:

```swift
import CoreVideo
import VisionCamera

func inspectFormat(frame: Frame) throws {
	let pixelBuffer = try frame.getPixelBuffer()
	print(frame.pixelFormat, CVPixelBufferGetPixelFormatType(pixelBuffer))
}
```

Do not infer row stride, plane count, or component packing from resolution alone. Use the frame and plane metadata described in <doc:FrameGuide>.

<!-- Adapted from react-native-vision-camera/docs/content/docs: pixel-formats-map. -->
