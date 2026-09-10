# Locking exposure, focus, and white balance

Manually set and lock exposure duration, ISO, focus, and white balance.

Exposure, focus, and white balance typically adjust automatically as the scene changes. For pro Camera apps, you can manually adjust and lock these values if the device supports it.

## Set exposure duration and ISO

If the ``CameraDevice`` supports custom exposure, set a custom exposure duration and ISO with `setExposureLocked(duration:iso:)`:

```swift
import VisionCamera

func setManualExposure(controller: CameraController) async throws {
	guard controller.device.supportsCustomExposure else { return }
	let duration = min(max(1.0 / 60.0, controller.minExposureDuration), controller.maxExposureDuration)
	let iso = min(max(100, controller.minISO), controller.maxISO)
	try await controller.setExposureLocked(duration: duration, iso: iso)
}
```

Exposure duration is measured in seconds. Both values must stay within the controller's supported bounds for its active format.

## Set focus lens position

If the device supports a custom lens position, set a lens position between `0` and `1`:

```swift
import VisionCamera

func setManualFocus(controller: CameraController) async throws {
	guard controller.device.supportsCustomLensPosition else { return }
	try await controller.setFocusLocked(lensPosition: 0.5)
}
```

Lens position is a normalized lens setting, not a distance in meters.

## Set white balance

To set a color temperature and tint, first convert them to native white-balance gains. Clamp each gain to the device's supported range before applying it:

```swift
import VisionCamera

func setDaylightWhiteBalance(controller: CameraController) async throws {
	guard controller.device.supportsCustomWhiteBalanceGains else { return }
	var gains = controller.convertWhiteBalanceTemperatureAndTintValues(
		whiteBalanceTemperatureAndTint: .init(temperature: 5500, tint: 0)
	)
	let maximum = controller.device.maxWhiteBalanceGain
	gains.redGain = min(max(gains.redGain, 1), maximum)
	gains.greenGain = min(max(gains.greenGain, 1), maximum)
	gains.blueGain = min(max(gains.blueGain, 1), maximum)
	try await controller.setWhiteBalanceLocked(whiteBalanceGains: gains)
}
```

## Get current values

The ``CameraController`` exposes `exposureDuration`, `iso`, `lensPosition`, and `whiteBalanceGains`. Use these values to display the current settings, or as starting points for manual controls.

## Lock current values

Locking current values is supported independently of manually specifying a lens position or white-balance gains. To lock the current values, for example after a <doc:TapToFocus> action, call `lockCurrentExposure()`, `lockCurrentFocus()`, or `lockCurrentWhiteBalance()`:

```swift
import VisionCamera

func lockCurrentMetering(controller: CameraController) async throws {
	let device = controller.device
	if device.supportsExposureLocking {
		try await controller.lockCurrentExposure()
	}
	if device.supportsFocusLocking {
		try await controller.lockCurrentFocus()
	}
	if device.supportsWhiteBalanceLocking {
		try await controller.lockCurrentWhiteBalance()
	}
}
```

Call `resetFocus()` to return to continuous automatic adjustment.

## React to subject area changes

Once you lock AE, AF, and AWB, the Camera keeps those values frozen no matter what the user points it at. If the user pans away from the subject, the locked values may no longer make sense.

`addSubjectAreaChangedListener(onSubjectAreaChanged:)` reports substantial changes to the scene. You can respond by resetting focus or showing a reset control. Retain its ``ListenerSubscription`` for as long as you need the listener, and call `remove()` when you are done.

<!-- Adapted from react-native-vision-camera/docs/content/docs/locking-ae-af-awb.mdx. -->
