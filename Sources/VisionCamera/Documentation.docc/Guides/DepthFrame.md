# A depth frame

Interpret, convert, and access depth or disparity data.

A ``Depth`` frame is an in-memory buffer that allows GPU and CPU access to individual depth points. It is typically streamed by a ``DepthOutput``, or attached to a ``Photo`` when depth delivery is enabled for that capture.

See <doc:DepthOutputGuide> for streaming depth frames.

## Orientation and mirroring

`orientation` and `isMirrored` describe the transform needed to present the depth frame. By default, these values are metadata. Set `DepthOutputOptions.rotatesBuffers` when you need physically transformed buffers instead.

The same orientation rules apply to video frames and depth frames. See <doc:Orientation>.

## Depth formats

A depth frame's `pixelFormat` describes the data in its buffer. Supported native layouts include 16-bit and 32-bit floating-point depth and disparity formats.

Depth values represent distance in meters. Disparity represents the relative shift between views and has a different interpretation. Use AVFoundation's depth conversion instead of treating disparity values as distances.

Inspect `accuracy`, `quality`, and `isFiltered` to understand the available data. Accuracy depends on the capture system and configuration, not just whether the buffer stores depth or disparity.

## Access depth data

`depthData` returns a retained native `AVDepthData`, and `pixelBuffer` returns its `CVPixelBuffer` map:

```swift
import AVFoundation
import VisionCamera

func nativeDepth(_ depth: Depth) -> AVDepthData {
	return depth.depthData
}
```

For scoped CPU access, use `withUnsafeBytes`. The pointer is read-only and valid only inside the closure. Respect `bytesPerRow` when reading individual rows.

```swift
import Foundation
import VisionCamera

func copyDepthBytes(_ depth: Depth) throws -> Data {
	return try depth.withUnsafeBytes { bytes in Data(bytes) }
}
```

## Convert formats

Use `converted(to:)` to convert a supported depth or disparity representation. For example, convert to 32-bit floating-point depth:

```swift
import VisionCamera

func depth32(_ depth: Depth) async throws -> Depth {
	return try await depth.converted(to: .depth32Bit)
}
```

The conversion returns a new depth wrapper. Unsupported conversion requests throw. `availablePixelFormats` lists the representations available for this sample.

## Calibration and lifetime

When available, `calibrationData` provides camera calibration details through ``CameraCalibrationData``. Keep calibration data with the sample it describes.

Swift releases the native depth data when no depth values or native references retain it. Independently retained `AVDepthData` and `CVPixelBuffer` references remain valid. See <doc:NativeBuffers>.

<!-- Adapted from react-native-vision-camera/docs/content/docs/a-depth-frame.mdx. -->
