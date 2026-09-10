# Exposure bias

Adjust the Camera's exposure using exposure bias compensation.

Exposure bias allows adjusting the Camera's exposure, where negative values result in darker, underexposed images, and positive values result in brighter, overexposed images. A value of `0` indicates no exposure bias compensation, which is the default.

## Set exposure bias

To adjust exposure bias on a ``CameraController``, use `setExposureBias()`:

```swift
import VisionCamera

func brighten(controller: CameraController) async throws {
	let device = controller.device
	guard device.supportsExposureBias else { return }
	let exposure = min(max(1, device.minExposureBias), device.maxExposureBias)
	try await controller.setExposureBias( exposure)
}
```

Make sure your ``CameraDevice`` supports exposure bias, and that your value stays within its `minExposureBias` and `maxExposureBias` range.

## Get exposure bias

The controller exposes the current value through `exposureBias`:

```swift
import VisionCamera

func printExposure(controller: CameraController) {
	print("Exposure bias:", controller.exposureBias)
}
```

For manual exposure duration and ISO, see <doc:LockingExposureFocusWhiteBalance>.

<!-- Adapted from react-native-vision-camera/docs/content/docs/exposure-bias.mdx. -->
