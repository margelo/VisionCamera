# Tap to focus

Start a focus metering action at a specific point in the Camera.

A "focus metering action" adjusts Auto-Exposure (AE), Auto-Focus (AF), and Auto-White-Balance (AWB) to bring a specific point in the Camera "into focus". This operation is also often called "3A metering".

## Start a focus metering action

First, create a ``MeteringPoint``. A ``PreviewView`` converts a point in the view to Camera coordinates:

```swift
import VisionCamera

@MainActor
func focusAtTap(
	x: Double,
	y: Double,
	preview: PreviewView,
	controller: CameraController
) async throws {
	let point = try preview.meteringPoint(at: .init(x: x, y: y))
	try await controller.focus(at: point, options: .init())
}
```

You can also create a metering point directly from normalized Camera coordinates between `0` and `1`:

```swift
import VisionCamera

func focusAtCenter(controller: CameraController) async throws {
	let point = MeteringPoint(location: .init(x: 0.5, y: 0.5))
	try await controller.focus(at: point, options: .init())
}
```

For a native tap gesture, attach a ``TapToFocusGestureController`` to your preview. See <doc:PreviewViewGuide>.

## Focus metering options

By default, the focus metering action adjusts all supported metering modes as fast as possible, then keeps that point continuously focused as the scene changes. After metering settles, focus automatically resets after 5 seconds.

Use ``FocusOptions`` to adjust this behavior.

### Metering modes

By default, all ``MeteringMode`` values supported by the current device are used. To adjust only exposure, pass `.ae`:

```swift
import VisionCamera

func meterExposure(controller: CameraController, point: MeteringPoint) async throws {
	guard controller.device.supportsExposureMetering else { return }
	try await controller.focus(at: point, options: .init(modes: [.ae]))
}
```

Now, only exposure is metered to the given point. Focus and white balance remain at their current positions.

> Important: If you pass a custom `modes` array, each mode must be supported by the current device.

### Focus responsiveness

The default `.snappy` responsiveness focuses as quickly as possible. This is suitable for photo capture, where users want to bring a scene into focus quickly.

When recording videos, this may feel disruptive. Use `.steady` for a slower focus transition.

### Scene adaptiveness

By default, `.continuous` keeps the given point in focus even as the scene changes.

For example, when focusing a football field, the Camera adjusts AE, AF, and AWB to bring the field into focus. Once a person walks through the Camera to grab a nice cold beer, the Camera might briefly adjust onto the person, causing the field to lose focus.

Use `.locked` to keep the metered values after the initial adjustment:

```swift
import VisionCamera

func lockOnSubject(controller: CameraController, point: MeteringPoint) async throws {
	try await controller.focus(
		at: point,
		options: .init(
			responsiveness: .steady,
			adaptiveness: .locked,
			reset: .never
		)
	)
}
```

### Auto reset

Use `.after(10)` to reset metering after 10 seconds, or `.never` to disable automatic reset. The default is `.after(5)`.

## Reset focus

To reset AE, AF, and AWB to the center of the Camera, call `resetFocus()`:

```swift
import VisionCamera

func resetMetering(controller: CameraController) async throws {
	try await controller.resetFocus()
}
```

Resetting focus also clears locked states and restores continuous automatic adjustment.

<!-- Adapted from react-native-vision-camera/docs/content/docs/tap-to-focus.mdx. -->
