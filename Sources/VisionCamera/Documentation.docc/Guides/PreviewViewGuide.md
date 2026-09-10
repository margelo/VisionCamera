# Display a preview view

Use UIKit to display a PreviewOutput and convert view coordinates.

``PreviewView`` is a UIKit view that renders the contents of a ``PreviewOutput``. See <doc:PreviewOutputGuide>.

```swift
import UIKit
import VisionCamera

@MainActor
func makePreview(output: PreviewOutput, in container: UIView) -> PreviewView {
	let preview = PreviewView(previewOutput: output)
	preview.resizeMode = .cover
	preview.frame = container.bounds
	preview.autoresizingMask = [.flexibleWidth, .flexibleHeight]
	container.addSubview(preview)
	return preview
}
```

Use `.cover` to fill the view, cropping when aspect ratios differ, or `.contain` to keep the entire image visible.

## Access methods on the view

The view provides methods for coordinate-system conversions and for creating metering points:

```swift
import VisionCamera

@MainActor
func cameraPoint(for point: Point, in preview: PreviewView) throws -> Point {
	try preview.convertViewPointToCameraPoint(viewPoint: point)
}
```

Coordinate conversions require an attached preview output. See <doc:CoordinateSystems>.

## Attach native gestures

The view supports native pinch-to-zoom and tap-to-focus gestures:

```swift
import VisionCamera

@MainActor
func attachGestures(to preview: PreviewView, controller: CameraController) {
	let zoom = ZoomGestureController()
	zoom.controller = controller
	let focus = TapToFocusGestureController()
	focus.controller = controller
	preview.gestureControllers = [zoom, focus]
}
```

Assign and retain a controller returned by session configuration. Gesture controllers hold a weak reference to it, so your Camera screen must keep a strong reference for as long as gestures are active. When the input device changes, update the gesture controllers to use the new ``CameraController``.

`onPreviewStarted` and `onPreviewStopped` report preview activity on the main queue. These describe the preview, which can start after the session itself starts.

<!-- Adapted from react-native-vision-camera/docs/content/docs: nativepreview-view,camera-view. -->
