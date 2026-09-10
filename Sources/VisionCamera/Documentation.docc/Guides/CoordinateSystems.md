# Coordinate systems

Convert points between Camera, preview, frame, and depth coordinates.

The Camera uses a native normalized coordinate system with values between `0` and `1`. A preview adds its own layout, orientation, scaling, and mirroring, so points need to be converted between these coordinate systems.

## Preview coordinates

A ``PreviewView`` provides conversions to and from Camera coordinates:

```swift
import VisionCamera

@MainActor
func cameraPoint(viewPoint: Point, preview: PreviewView) throws -> Point {
	return try preview.convertViewPointToCameraPoint(viewPoint: viewPoint)
}

@MainActor
func viewPoint(cameraPoint: Point, preview: PreviewView) throws -> Point {
	return try preview.convertCameraPointToViewPoint(cameraPoint: cameraPoint)
}
```

View coordinates are measured in UIKit points relative to the preview's bounds. Conversions account for the current preview configuration. The preview must have an attached output.

### Scanned objects

Use `convertScannedObjectCoordinatesToViewCoordinates(scannedObject:)` to convert all coordinates in a ``ScannedObject``. See <doc:ScannedObjects>.

### Metering points

A ``MeteringPoint`` provides a convenient way to convert tap coordinates to Camera coordinates. Create one with `PreviewView.meteringPoint(at:)`, then pass it to the controller's focus method. See <doc:TapToFocus>.

## Frame coordinates

Frames use pixel coordinates in their native buffer dimensions. Use `convertFramePointToCameraPoint(framePoint:)` or `convertCameraPointToFramePoint(cameraPoint:)` to convert between frame pixels and normalized Camera coordinates.

Putting the conversions together maps a detected point in a frame to the preview:

```swift
import VisionCamera

@MainActor
func overlayPoint(
	framePoint: Point,
	frame: Frame,
	preview: PreviewView
) throws -> Point {
	let cameraPoint = try frame.convertFramePointToCameraPoint(framePoint: framePoint)
	return try preview.convertCameraPointToViewPoint(cameraPoint: cameraPoint)
}
```

This is useful when your processing detects an object and you want to display an indicator in the preview. If your processing library has already rotated, mirrored, cropped, or normalized the image, first convert its result back to the frame's pixel coordinates.

## Depth coordinates

``Depth`` provides `convertDepthPointToCameraPoint(depthPoint:)` and `convertCameraPointToDepthPoint(cameraPoint:)` for depth-map coordinates. Keep the depth map's dimensions and calibration in mind when comparing it with video pixels.

<!-- Adapted from react-native-vision-camera/docs/content/docs: coordinate-systems. -->
