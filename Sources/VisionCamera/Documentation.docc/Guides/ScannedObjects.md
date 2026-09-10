# Scanned objects

Inspect detected codes and faces, and convert their coordinates to a preview.

A ``ScannedObject`` is an object, such as a machine-readable code or a human face, scanned by a ``CameraObjectOutput``.

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
			if face.hasRollAngle { print("Roll:", face.rollAngle) }
			if face.hasYawAngle { print("Yaw:", face.yawAngle) }
		default:
			print("Object:", object.type, object.boundingBox)
		}
	}
}
```

Each object also exposes its native `AVMetadataObject` through `object`.

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
