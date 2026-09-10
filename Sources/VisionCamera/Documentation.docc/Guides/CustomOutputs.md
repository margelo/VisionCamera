# Custom Camera outputs

Connect your own AVFoundation output to a Camera session.

Third-party libraries can implement ``CameraOutput`` and ``NativeCameraOutput`` to build a custom output that connects to the Camera just like any built-in output.

## Implement the native output contract

`NativeCameraOutput` exposes the actual `AVCaptureOutput` that the session connects. It also declares audio and depth requirements and participates in resolution negotiation.

This example wraps an `AVCaptureVideoDataOutput` with a caller-provided native delegate:

```swift
import AVFoundation
import CoreVideo
import VisionCamera

final class SampleBufferOutput: CameraOutput, NativeCameraOutput {
	let output = AVCaptureVideoDataOutput()
	let mediaType: MediaType = .video
	let requiresAudioInput = false
	let requiresDepthFormat = false
	let streamType: StreamType = .video
	let targetResolution: ResolutionRule = .closestTo(.init(width: 720, height: 1280))

	private let delegate: any AVCaptureVideoDataOutputSampleBufferDelegate
	private let queue = DispatchQueue(label: "com.example.camera.samples")
	private var mirrorMode: MirrorMode = .auto

	var outputOrientation: CameraOrientation = .up {
		didSet { applyPresentation() }
	}

	var currentResolution: Size? {
		guard let format = output.connection(with: .video)?.inputPorts.first?.formatDescription else {
			return nil
		}
		let dimensions = CMVideoFormatDescriptionGetDimensions(format)
		return Size(width: Double(dimensions.width), height: Double(dimensions.height))
	}

	init(delegate: any AVCaptureVideoDataOutputSampleBufferDelegate) {
		self.delegate = delegate
		output.videoSettings = [
			kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
		]
		output.alwaysDiscardsLateVideoFrames = true
		output.setSampleBufferDelegate(delegate, queue: queue)
	}

	func configure(config: OutputConfiguration) {
		mirrorMode = config.mirrorMode
		applyPresentation()
	}

	private func applyPresentation() {
		guard let connection = output.connection(with: .video) else { return }

		if #available(iOS 17, *) {
			let angle: CGFloat
			switch outputOrientation {
			case .up: angle = 90
			case .right: angle = 180
			case .down: angle = 270
			case .left: angle = 0
			}
			if connection.isVideoRotationAngleSupported(angle) {
				connection.videoRotationAngle = angle
			}
		} else if connection.isVideoOrientationSupported {
			switch outputOrientation {
			case .up: connection.videoOrientation = .portrait
			case .right: connection.videoOrientation = .landscapeLeft
			case .down: connection.videoOrientation = .portraitUpsideDown
			case .left: connection.videoOrientation = .landscapeRight
			}
		}

		switch mirrorMode {
		case .auto:
			connection.automaticallyAdjustsVideoMirroring = true
		case .on, .off:
			if connection.isVideoMirroringSupported {
				connection.automaticallyAdjustsVideoMirroring = false
				connection.isVideoMirrored = mirrorMode == .on
			}
		}
	}
}
```

The session calls `configure(config:)` during its configuration batch on the session's serial queue. The method can throw to reject an unsupported format or setting before AVFoundation applies it. `MediaType.other(_:)` preserves native media identifiers for custom outputs. Do not independently add this native output to another capture session. Coordinate subsequent configuration changes with the owner of your session.

This sample requests physical buffer rotation and native mirroring. Its delegate receives transformed buffers. For processing that accepts orientation metadata, you can design an output that leaves pixels in sensor orientation instead. See <doc:Orientation>.

## Attach the output

Create the custom output and include it in a connection:

```swift
import AVFoundation
import VisionCamera

func attachCustomOutput(
	session: CameraSession,
	output: any CameraOutput
) async throws {
	_ = try await session.configure(connections: [
		.init(
			input: .position(.back),
			outputs: [.init(output: output)],
			constraints: [.resolutionBias(.init(resolutionBias: output))]
		)
	])
}
```

Pass your `SampleBufferOutput` as `output`. The session negotiates its target resolution with the other outputs and constraints. See <doc:Constraints>.

## Own callback delivery and buffer lifetime

A custom output owns its delegate and callback queue. Keep callbacks short, retain native sample buffers only while processing them, and avoid unbounded frame queues.

If you wrap a native sample in ``Frame``, provide ``MediaSampleMetadata`` describing the sample's actual timestamp, orientation, and mirroring. See <doc:NativeBuffers> and <doc:AsyncFrameProcessing>.

<!-- Adapted from react-native-vision-camera/docs/content/docs/custom-native-camera-outputs.mdx. -->
