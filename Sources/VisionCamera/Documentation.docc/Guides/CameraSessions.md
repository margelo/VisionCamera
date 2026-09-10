# Camera session

Connect inputs to outputs and control the Camera's lifecycle.

A ``CameraSession`` connects inputs, see <doc:CameraDevices>, to outputs, see <doc:CameraOutputs>, and orchestrates lifecycle.

## Create a CameraSession

```swift
import VisionCamera

func createSession() -> CameraSession {
	CameraSession()
}
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
	let controllers = try await session.configure(connections: [
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

## Handle interruptions

A ``CameraSession`` can be interrupted, for example due to an incoming FaceTime call or device thermal throttling. See ``InterruptionReason``.

```swift
import VisionCamera

func observeInterruptions(session: CameraSession) -> [ListenerSubscription] {
	[
		session.addOnInterruptionStartedListener { reason in
			print("Camera interrupted:", reason)
		},
		session.addOnInterruptionEndedListener {
			print("Camera interruption ended")
		},
		session.addOnErrorListener { error in
			print("Camera error:", error)
		}
	]
}
```

Retain subscriptions while listening and call `remove()` when finished. Camera callbacks may arrive outside the main queue. Dispatch UIKit changes to the main queue.

## Stop a CameraSession

Call `await session.stop()` to stop capture while keeping the session configured. To remove connections, configure the stopped session with an empty connections array. Release your references when the session is no longer needed. See <doc:Lifecycle>.

<!-- Adapted from react-native-vision-camera/docs/content/docs: camera-session. -->
