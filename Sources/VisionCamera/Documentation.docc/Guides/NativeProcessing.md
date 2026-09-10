# Native frame processing

Process frames with ordinary Swift functions and Apple's image processing APIs.

Native frame processing is a Swift function that receives a ``Frame`` and performs work on its native pixels. The function can accept additional arguments and return whatever result your app needs.

## Read a native sample buffer

The frame exposes its optional `sampleBuffer` and `pixelBuffer` directly:

```swift
import CoreMedia
import VisionCamera

func presentationTime(frame: Frame) throws -> CMTime {
	guard let sampleBuffer = frame.sampleBuffer else {
		throw CameraError(message: "Frame has been disposed.")
	}
	return CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
}
```

For APIs that work with a `CVPixelBuffer`, use `getPixelBuffer()`. The returned object is retained and can be passed directly to Core Image, Vision, or other native processing code.

## Process a frame with Vision

Vision accepts a pixel buffer and its presentation orientation. This example detects barcodes and returns their payloads:

```swift
import ImageIO
import UIKit
import Vision
import VisionCamera

func scanBarcodes(frame: Frame) throws -> [String] {
	let orientation: CGImagePropertyOrientation
	switch frame.metadata.uiImageOrientation {
	case .up: orientation = .up
	case .upMirrored: orientation = .upMirrored
	case .down: orientation = .down
	case .downMirrored: orientation = .downMirrored
	case .left: orientation = .left
	case .leftMirrored: orientation = .leftMirrored
	case .right: orientation = .right
	case .rightMirrored: orientation = .rightMirrored
	@unknown default:
		throw CameraError(message: "Unsupported image orientation.")
	}

	let request = VNDetectBarcodesRequest()
	request.symbologies = [.qr]
	let handler = VNImageRequestHandler(
		cvPixelBuffer: try frame.getPixelBuffer(),
		orientation: orientation
	)
	try handler.perform([request])
	return request.results?.compactMap { $0.payloadStringValue } ?? []
}
```

Register the function with your frame output:

```swift
import VisionCamera

func installProcessor(
	output: CameraFrameOutput,
	process: @escaping (Frame) throws -> [String]
) async {
	await output.setOnFrameCallback { frame in
		do {
			print(try process(frame))
		} catch {
			print("Processing failed:", error)
		}
	}
}
```

Pass `scanBarcodes` as `process` when installing the processor. If QR scanning is all you need, the native <doc:ObjectOutput> can scan without a custom frame processing pipeline.

## Processing budget

At 30 FPS, a new frame arrives roughly every 33 ms. At 60 FPS, the interval is about 17 ms. Processing that exceeds the budget causes frame drops or increases buffering.

Choose a suitable resolution and pixel format before adding more processing. For slower work, use the bounded worker pattern in <doc:AsyncFrameProcessing>.

## Depth

The same approach applies to ``Depth``. Pass `AVDepthData` or its pixel buffer to your native processing function. See <doc:DepthFrame>.

<!-- Adapted from react-native-vision-camera/docs/content/docs: native-frame-processor-plugins. -->
