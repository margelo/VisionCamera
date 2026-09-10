# Camera controller

Adjust zoom, exposure, focus, and other properties of a configured Camera.

A ``CameraController`` controls an active ``CameraSession``'s properties, like zoom, exposure, or focus.

## Get a CameraController

The session's configuration method returns one controller per configured connection. In single-camera sessions, this is one or zero.

```swift
import VisionCamera

func configureController(session: CameraSession, output: any CameraOutput) async throws -> CameraController? {
	let controllers = try await session.configure([
		.init(input: .position(.back), outputs: [.init(output: output)])
	])
	return controllers.first
}
```

Keep the returned controller for the configured input. When changing devices, use the controller returned by the new configuration.

## Probe for feature availability

Since Camera hardware varies, always probe for available features. To use exposure bias, for example, make sure the device supports it:

```swift
import VisionCamera

func brighten(controller: CameraController) async throws {
	guard controller.device.supportsExposureBias else { return }
	let exposure = min(1, controller.device.maxExposureBias)
	try await controller.setExposureBias( exposure)
}
```

Properties report current device state. Operations that change hardware state are asynchronous and run on the controller's Camera queue. Await them and handle failures such as unsupported features or device configuration errors.

See <doc:Zooming>, <doc:ExposureBias>, <doc:TapToFocus>, and <doc:LockingExposureFocusWhiteBalance>.

<!-- Adapted from react-native-vision-camera/docs/content/docs: camera-controller. -->
