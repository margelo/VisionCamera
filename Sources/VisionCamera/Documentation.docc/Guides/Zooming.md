# Zooming

Zoom in and out, animate zoom changes, and understand virtual device switchover.

Zooming allows you to adjust the crop area of a Camera. To zoom on a ``CameraController``, use `setZoom(zoom:)`:

```swift
import VisionCamera

func zoomIn(controller: CameraController) async throws {
	let zoom = min(max(2, controller.minZoom), controller.maxZoom)
	try await controller.setZoom(zoom: zoom)
}
```

Make sure your zoom value always stays within the controller's supported `minZoom` and `maxZoom` range. These limits reflect the active configuration.

## Zoom animations

Zoom animations can be started using `startZoomAnimation(zoom:rate:)`. The rate controls how quickly the zoom changes.

```swift
import VisionCamera

func animateZoom(controller: CameraController) async throws {
	let target = min(3, controller.maxZoom)
	try await controller.startZoomAnimation(zoom: target, rate: 2)
}

func cancelZoom(controller: CameraController) async throws {
	try await controller.cancelZoomAnimation()
}
```

For pinch-to-zoom, attach a ``ZoomGestureController`` to your ``PreviewView``. See <doc:PreviewViewGuide>.

## Virtual device zoom switchover

Virtual Camera Devices contain multiple constituent physical devices, and automatically switch between devices depending on the zoom ratio.

To find out at which zoom factors a virtual device may switch to a different physical device, use `CameraDevice.zoomLensSwitchFactors`. These factors mark possible switchovers. Scene conditions can affect which physical device the Camera uses.

## Current and displayable zoom

A ``CameraController`` exposes its current `zoom` and a user-displayable `displayableZoomFactor`.

```swift
import VisionCamera

func printZoom(controller: CameraController) {
	print("Native zoom:", controller.zoom)
	if #available(iOS 18.0, *) {
		print("Display zoom:", controller.displayableZoomFactor)
	}
	print("Lens switch factors:", controller.device.zoomLensSwitchFactors)
}
```

`zoom` uses AVFoundation's native zoom factor. A virtual Camera's minimum native factor does not necessarily correspond to the familiar "1x" wide-angle view. `displayableZoomFactor` requires iOS 18 or later and applies Apple's display multiplier.

Use native factors when setting zoom. Use `displayableZoomFactor` when displaying the current value in your UI.

<!-- Adapted from react-native-vision-camera/docs/content/docs/zooming.mdx. -->
