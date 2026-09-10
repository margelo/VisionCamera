# Orientation

Choose interface or device orientation and understand how outputs apply it.

A Camera sensor has a fixed orientation relative to the device. Rotating the phone changes how its images need to be presented, and each output applies that orientation differently.

## Follow orientation changes

In most cases, output orientation follows either the app's interface orientation or the phone's physical device orientation:

- Interface orientation changes only when the UI rotates. If the UI is locked to portrait and the phone is held sideways, the output stays upright for the portrait interface.
- Device orientation changes when the phone physically rotates, even if the UI remains locked to portrait. This suits photography apps whose capture orientation follows the phone.

Create a ``DeviceOrientationManager`` or ``InterfaceOrientationManager`` and apply its updates to your capture outputs:

```swift
import Foundation
import VisionCamera

@MainActor
func followDeviceOrientation(photoOutput: PhotoOutput) throws -> any OrientationManager {
	let manager = DeviceOrientationManager()
	if let orientation = manager.currentOrientation {
		photoOutput.outputOrientation = orientation
	}
	try manager.startUpdates { [weak photoOutput] orientation in
		DispatchQueue.main.async {
			photoOutput?.outputOrientation = orientation
		}
	}
	return manager
}
```

Retain the manager while updates are needed, then call `stopUpdates()`. `currentOrientation` is `nil` until a usable orientation is known. Interface updates arrive on the main queue. Device updates arrive on the manager's serial queue.

Apply changes from one owner in your app. Avoid changing output properties concurrently from several callbacks or while another owner is reconfiguring the session.

## Set orientation manually

For manual control, assign an output's `outputOrientation` directly. ``CameraOrientation`` has `.up`, `.right`, `.down`, and `.left` values.

The preview follows the interface orientation automatically. `PreviewOutput.outputOrientation` is read-only.

## Rotate UI controls

When capture follows device orientation but the interface is locked, you can rotate individual buttons as the orientation changes. Keep this presentation choice in your UIKit code and update the views on the main actor.

## How outputs apply orientation

Photos carry presentation orientation in their metadata. The photo-to-`UIImage` conversion respects that orientation.

Recorded videos use the selected backend's orientation handling and track presentation. Choose the desired orientation before recording starts.

A preview displays with the current interface orientation through its native preview layer.

For streamed frames and depth, orientation and mirroring are metadata by default. The consumer must interpret `orientation` and `isMirrored` when processing or rendering the buffer. See <doc:FrameGuide> and <doc:DepthFrame>.

### Physical buffer rotation

Set `rotatesBuffers` in ``FrameOutputOptions`` or ``DepthOutputOptions`` to request physically transformed buffers. Those samples report `.up` and `false`, meaning no additional presentation transform is needed.

Physical transformation adds processing. If your processing library accepts orientation and mirroring flags, passing metadata can avoid that work. See <doc:NativeProcessing> for a Vision example.

<!-- Adapted from react-native-vision-camera/docs/content/docs: orientation. -->
