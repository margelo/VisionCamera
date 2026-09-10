# Coordinate systems

Convert points between Camera, preview, frame, and depth coordinates.

The Camera uses a native normalized coordinate system with values between `0` and `1`. A preview adds its own layout, orientation, scaling, and mirroring, so points need to be converted between these coordinate systems.

## Preview coordinates

A ``PreviewView`` provides conversions to and from Camera coordinates:

```swift
import CoreGraphics
import VisionCamera

@MainActor
func cameraPoint(viewPoint: CGPoint, preview: PreviewView) throws -> CGPoint {
	return try preview.cameraPoint(from: viewPoint)
}

@MainActor
func viewPoint(cameraPoint: CGPoint, preview: PreviewView) throws -> CGPoint {
	return try preview.point(fromCameraPoint: cameraPoint)
}
```

View coordinates are measured in UIKit points relative to the preview's bounds. Conversions account for the current preview configuration. The preview must have an attached output.

### Scanned objects

Use `convertedToViewCoordinates()` to convert all coordinates in a ``ScannedObject``. See <doc:ScannedObjects>.

### Metering points

A ``MeteringPoint`` provides a convenient way to convert tap coordinates to Camera coordinates. Create one with `PreviewView.meteringPoint(at:size:)`, then pass it to the controller's focus method. See <doc:TapToFocus>.

## Frame coordinates

Frames use pixel coordinates in their native buffer dimensions. Use `cameraPoint(from:)` or `point(fromCameraPoint:)` to convert between frame pixels and normalized Camera coordinates.

Putting the conversions together maps a detected point in a frame to the preview:

```swift
import CoreGraphics
import VisionCamera

@MainActor
func overlayPoint(
	framePoint: CGPoint,
	frame: Frame,
	preview: PreviewView
) throws -> CGPoint {
	let cameraPoint = try frame.cameraPoint(from: framePoint)
	return try preview.point(fromCameraPoint: cameraPoint)
}
```

This is useful when your processing detects an object and you want to display an indicator in the preview. If your processing library has already rotated, mirrored, cropped, or normalized the image, first convert its result back to the frame's pixel coordinates.

## Depth coordinates

``Depth`` provides `cameraPoint(from:)` and `point(fromCameraPoint:)` for depth-map coordinates. Keep the depth map's dimensions and calibration in mind when comparing it with video pixels.

<!-- Adapted from react-native-vision-camera/docs/content/docs: coordinate-systems. -->
