# Lifecycle

Understand a Camera session's idle, ready, and active states.

The ``CameraSession`` has three lifecycle stages:

- Idle: no connections, and not running.
- Ready: connections configured, but not yet started.
- Active: connections configured and started.

## Control a SwiftUI Camera

Pass `isActive` to ``Camera``. Include both scene activity and screen visibility. For example, use `isActive: scenePhase == .active && isCameraScreenVisible`.

The Camera configures before starting, keeps its configuration while inactive, and stops and disconnects when removed from the hierarchy. It removes its event listeners, orientation updates, and gestures during teardown. Rapid input changes are serialized so an old configuration cannot restart an inactive Camera. See <doc:SwiftUICamera>.

Set recording policy in your app. If hiding the Camera should finish or cancel a recording, await that operation before removing its output.

## Switch a native session between lifecycle stages

Move an active Camera session to the ready state when it goes out of view, to prevent the Camera from running in the background. This stops the Camera while keeping it configured and prepared in memory.

```swift
import VisionCamera

func setCameraVisible(_ visible: Bool, session: CameraSession) async {
	if visible {
		await session.start()
	} else {
		await session.stop()
	}
}
```

In UIKit, coordinate this with your view controller's visibility and your scene's active state. Treat both as inputs to whether the Camera should run. Await configuration before starting, and serialize your lifecycle decisions so an earlier start request cannot revive a screen that has already disappeared.

## Stop or release

A stopped ``CameraSession`` remains fully configured in memory, causing subsequent starts to be much faster.

To release capture connections while retaining the session object:

```swift
import VisionCamera

func disconnectCamera(session: CameraSession) async throws {
	await session.stop()
	_ = try await session.configure(connections: [])
}
```

Release the session, outputs, views, and listener subscriptions when you no longer need them. Remove callbacks that capture their owner, or capture the owner weakly, to avoid a reference cycle.

## Reconfigure

When the ``CameraSession`` is reconfigured, for example when attaching or removing outputs, changing the input device, or adjusting constraints, the new configuration has to be submitted to the hardware. This can briefly interrupt frame delivery.

As a general tip, avoid reconfigurations as much as possible. Use a ``CameraController`` for zoom, exposure, and focus adjustments.

<!-- Adapted from react-native-vision-camera/docs/content/docs: lifecycle,camera-view. -->
