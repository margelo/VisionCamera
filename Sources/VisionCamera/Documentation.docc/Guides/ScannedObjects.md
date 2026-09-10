# Scanned objects

Inspect detected codes and faces, and convert their coordinates to a preview.

A ``ScannedObject`` is an object, such as a machine-readable code or a human face, scanned by a ``ObjectOutput``.

## Object types

``ScannedObject`` is the common protocol for scanned results. ``MetadataObject`` is the general wrapper, and ``ScannedCode`` and ``ScannedFace`` expose additional information:

```swift
import VisionCamera

func inspect(objects: [any ScannedObject]) {
	for object in objects {
		switch object {
		case let code as ScannedCode:
			print("Code:", code.value ?? "", code.cornerPoints)
		case let face as ScannedFace:
			print("Face:", face.faceID)
			if let roll = face.rollAngle { print("Roll:", roll) }
			if let yaw = face.yawAngle { print("Yaw:", yaw) }
		default:
			print("Object:", object.type, object.boundingBox)
		}
	}
}
```

Each object exposes its native `AVMetadataObject` through `object`. Its `type` is an `AVMetadataObject.ObjectType`, preserving native identifiers without an unknown-case conversion. Face IDs are integers, and unavailable roll or yaw angles are `nil`.

## Synchronize metadata with frames

Connect a frame output and an object output to the same session before constructing ``OutputSynchronizer``. The synchronizer delivers ``SynchronizedFrame/metadata(objects:timestamp:)`` alongside frame or depth samples. An empty metadata array means no objects were detected at that timestamp. Use the synchronizer callback while it owns the outputs, because AVFoundation replaces each output's individual delegate.

The synchronizer accepts one or more video data, depth data, metadata, or native audio data outputs. Native audio integrations receive their original `CMSampleBuffer` through ``SynchronizedFrame/audio(_:)``. Photo and movie-file outputs throw during synchronizer creation. Duplicate or disconnected outputs also throw.

Frame and depth samples keep the orientation and mirroring requested by their outputs. Synchronizing a ``VideoFrameOutput`` transfers its native sample delegate to the synchronizer, so that output cannot simultaneously feed its recorder.

## Coordinate conversions

A scanned object's `boundingBox` describes its location in normalized Camera coordinates between `0` and `1`. A scanned code also exposes `cornerPoints`, and a scanned face can expose roll and yaw angles.

Convert the whole result to preview coordinates using ``PreviewView``:

```swift
import VisionCamera

@MainActor
func convertObject(
	_ object: any ScannedObject,
	to preview: PreviewView
) throws -> any ScannedObject {
	return try preview.convertScannedObjectCoordinatesToViewCoordinates(scannedObject: object)
}
```

The returned result uses view coordinates suitable for drawing overlays. Perform this conversion on the main actor with the current preview layout. See <doc:CoordinateSystems>.

<!-- Adapted from react-native-vision-camera/docs/content/docs: a-scannedobject. -->
