# The object output

Scan machine-readable codes and faces with the native Camera pipeline.

The ``ObjectOutput`` scans objects using AVFoundation's native metadata output. It can detect supported codes and faces without a custom frame processing pipeline.

## Create an object output

Choose the types you need, then register a callback and connect the output:

```swift
import VisionCamera

func prepareScanner() async throws -> (CameraSession, ObjectOutput) {
	let session = CameraSession()
	let output = ObjectOutput(options: .init(enabledObjectTypes: [.qr]))
	await output.setObjectHandler { objects in
		for case let code as ScannedCode in objects {
			print("QR code:", code.value ?? "")
		}
	}
	_ = try await session.configure([
		.init(input: .position(.back), outputs: [.init(output: output)])
	])
	await session.start()
	return (session, output)
}
```

Request Camera permission first. Retain the session and output while scanning. Add a <doc:PreviewOutputGuide> to the same connection if you want a live preview.

Configuration throws if AVFoundation does not support a requested type in the active configuration. Enable only the types you need. See ``ObjectOutputOptions``. Types use `AVMetadataObject.ObjectType`, so newer metadata types follow Apple's SDK availability checks. Bodies, animal heads, and salient objects remain available when the connected camera supports them.

## Receive scanned objects

The callback receives values conforming to ``ScannedObject``. A ``ScannedCode`` represents a machine-readable code, while a ``ScannedFace`` represents a detected face.

Callbacks run on the object output's queue. Dispatch UI updates to the main queue, and clear the callback with `await output.setObjectHandler(nil)` when scanning is no longer needed.

A successful session configuration means the metadata output is connected and all requested types are enabled. It does not mean an object has been recognized. Recognition depends on the supported types, visible target, focus, lighting, and image size.

See <doc:ScannedObjects> for result types and coordinate conversions.

## Native scanning or custom processing

Use the object output when its supported formats and metadata meet your needs. A custom <doc:NativeProcessing> pipeline gives you more control over the processing algorithm and results, but adds work to the frame path.

VisionCamera is a good fit when scanning is part of a custom Camera flow. The Camera view stays inside your app, so you can draw your own overlay, use custom zoom and focus controls, scan multiple codes, convert coordinates, and decide when a scanned code should be accepted.

Keep a camera session when you also need to capture photos or record videos. A standalone scanning UI can be a separate app-level choice when you only need a single result.

Detected objects use unrotated, unmirrored capture-device coordinates. `outputOrientation` is read-only, and an explicit `.on` mirror mode is rejected. Use `PreviewView.convertedToViewCoordinates(_:)` for overlays.

<!-- Adapted from react-native-vision-camera/docs/content/docs: object-output, barcode-scanner-vs-object-output, visioncamera-vs-data-scanner. -->
