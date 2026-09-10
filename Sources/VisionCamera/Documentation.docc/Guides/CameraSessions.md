# Camera session

Connect inputs to outputs and control the Camera's lifecycle.

A ``CameraSession`` connects inputs, see <doc:CameraDevices>, to outputs, see <doc:CameraOutputs>, and orchestrates lifecycle.

The SwiftUI ``Camera`` manages these steps for a single Camera. Use a session directly for UIKit, multi-camera capture, or custom ownership. See <doc:SwiftUICamera>.

## Create a CameraSession

```swift
import VisionCamera

let session = CameraSession()
```

See <doc:MultiCamera> for multi-camera sessions.

## Configure the session

Using a ``CameraSession`` requires you to explicitly configure, start, and stop the session yourself.

```swift
import VisionCamera

func configurePhotoCapture(
	session: CameraSession,
	photoOutput: PhotoOutput
) async throws -> [CameraController] {
	let controllers = try await session.configure([
		CameraSessionConnection(
			input: .position(.back),
			outputs: [CameraOutputConfiguration(output: photoOutput)])
	])
	await session.start()
	return controllers
}
```

Handle most configuration before you start the session, as configuration while the session is running can be expensive and cause stutters.

There's three levels of Camera configuration:

1. Session-wide configuration, see ``CameraSessionConfiguration``.
2. Connection-wide configuration, see ``CameraSessionConnection`` and ``Constraint``.
3. Output-specific configuration, see ``CameraOutputConfiguration``.

> Note: Properties like zoom, exposure, or focus can be adjusted without session reconfiguration. See <doc:CameraControllerGuide>.

## Mix audio with other apps

On iOS 18 and later, configure whether AVFoundation mixes recording audio with other apps:

```swift
import VisionCamera

@available(iOS 18.0, *)
func configureAudioMixing(session: CameraSession, connections: [CameraSessionConnection]) async throws {
	let config = CameraSessionConfiguration(allowsBackgroundAudioPlayback: true)
	_ = try await session.configure(connections, configuration: config)
}
```

This setting applies when the capture session automatically configures the app's shared audio session. Leave it unspecified to preserve the current setting.

## Handle interruptions

A ``CameraSession`` can be interrupted, for example due to an incoming FaceTime call or device thermal throttling. See ``InterruptionReason``.

```swift
import VisionCamera

func observeInterruptions(session: CameraSession) -> [ObservationToken] {
	[
		session.observeInterruptionStarted { reason in
			print("Camera interrupted:", reason)
		},
		session.observeInterruptionEnded {
			print("Camera interruption ended")
		},
		session.observeErrors { error in
			print("Camera error:", error)
		}
	]
}
```

Retain observation tokens while listening, then call `cancel()` or release them when finished. Camera callbacks may arrive outside the main queue. Dispatch UIKit changes to the main queue.

## Stop a CameraSession

Call `await session.stop()` to stop capture while keeping the session configured. To remove connections, configure the stopped session with an empty connections array. Release your references when the session is no longer needed. See <doc:Lifecycle>.

<!-- Adapted from react-native-vision-camera/docs/content/docs: camera-session. -->
