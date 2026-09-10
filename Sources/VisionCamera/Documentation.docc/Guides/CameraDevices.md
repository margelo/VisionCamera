# Camera devices

Choose a Camera input and inspect its capabilities.

A ``CameraDevice`` is a camera on your phone that can be used as an input for a ``CameraSession``. The type reports supported Camera features such as zoom ranges, available resolutions, supported FPS ranges, device-specific metadata, and more.

In most cases, the default back Camera is the most fitting:

```swift
import VisionCamera

var defaultBackCamera: CameraDevice? {
	VisionCamera.defaultCamera(for: .back)
}
```

## Physical device types

There are three common physical lens types, see ``DeviceType``:

- Ultra-wide-angle: a Camera with an ultra-wide field of view, like a fish-eye view. Often referred to as "the 0.5x Camera".
- Wide-angle: a Camera with a wide field of view suitable for everyday mobile photography. Often referred to as "the 1x Camera", or "the default Camera".
- Telephoto: a Camera with a narrow field of view suitable for large zooms. Often referred to as "the 3x Camera" or "the 5x Camera".

The device list can also contain TrueDepth, LiDAR, and external Cameras.

## Virtual devices

Some ``CameraDevice`` instances consist of two or more physical devices to make up a single virtual device, like the triple Camera. It consists of the ultra-wide-angle, wide-angle, and telephoto Cameras.

Virtual devices support automatically switching between their physical devices as the zoom changes. See <doc:Zooming>.

## Select a Camera by criteria

The Camera device used for your session affects available features and resolutions. More complex devices can also take longer to start.

For simple Camera use-cases, it's often a good idea to select a single physical Camera. It loads faster than a bigger virtual Camera, and supports most available resolutions.

```swift
import AVFoundation
import VisionCamera

func tripleCamera() -> CameraDevice? {
	VisionCamera.cameraDevices.first {
		$0.device.position == .back && $0.device.deviceType == .builtInTripleCamera
	}
}
```

Inspect `physicalDevices` to see a virtual Camera's constituent devices. Use the selected virtual device itself as your session input.

## Individual capabilities

A ``CameraDevice`` exposes individually supported capabilities such as resolutions, dynamic ranges, FPS ranges, and video stabilization modes. These are not guaranteed to work in every combination.

VisionCamera uses ``Constraint`` values to combine features and find a best-matching Camera configuration. See <doc:Constraints>.

## External devices and device changes

VisionCamera can use external Cameras that AVFoundation exposes, including supported UVC Cameras on iPad. External-device discovery requires iOS 17 or later.

```swift
import VisionCamera

func observeDevices() -> ObservationToken {
	VisionCamera.observeCameraDevices { devices in
		for device in devices {
			print(device.id, device.localizedName)
		}
	}
}
```

When a Camera is plugged in or unplugged, query ``VisionCamera/cameraDevices`` again and avoid using a removed device. Retain the observation token while listening, then call `cancel()` or release it when finished.

## Use the Camera device

Pass the selected device as `.device(device)` in a ``CameraSessionConnection``. Use `.position(.back)` or `.position(.front)` when you want the session to select the default Camera at that position.

<!-- Adapted from react-native-vision-camera/docs/content/docs: devices. -->
