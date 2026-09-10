# Build a SwiftUI Camera

Mount a Camera, retain capture outputs, and update Camera controls from your app's state.

Install VisionCamera with Swift Package Manager and request permission before mounting. See <doc:GettingStarted> for a complete permission flow. SwiftUI and UIKit use the same Camera engine and support the same capture outputs.

## Retain capture outputs

Create outputs once in a model owned by `@StateObject`. Pass them to ``Camera`` and capture through those same objects:

```swift
import SwiftUI
import VisionCamera

@MainActor
final class PhotoCameraModel: ObservableObject {
	let photo = PhotoOutput()
}

struct PhotoCameraScreen: View {
	let device: CameraDevice
	@Environment(\.scenePhase) private var scenePhase
	@StateObject private var model = PhotoCameraModel()
	@State private var isReady = false
	@State private var zoom = 1.0
	@State private var message = ""

	var body: some View {
		ZStack(alignment: .bottom) {
			Camera(device: device, isActive: scenePhase == .active, outputs: [model.photo])
				.zoom($zoom)
				.enableZoomGesture()
				.enableTapToFocusGesture()
				.onStarted { isReady = true }
				.onStopped { isReady = false }
				.onError { message = $0.localizedDescription }

			VStack {
				Text(message)
				Button("Take Photo") {
					Task {
						do {
							let photo = try await model.photo.capturePhoto(settings: .init())
							let path = try await photo.writeToTemporaryFile()
							message = "Saved to \(path)"
						} catch {
							message = error.localizedDescription
						}
					}
				}
				.disabled(!isReady || scenePhase != .active)
			}
			.padding()
		}
	}
}
```

Do not create `PhotoOutput()`, `VideoFrameOutput()`, or other capture objects inside `body`. A new output identity changes the session graph. `@StateObject` initializes its model once per view identity, as described in [Apple's state ownership documentation](https://developer.apple.com/documentation/swiftui/stateobject).

The runnable app in `ExampleSwiftUI` adds permission handling, camera switching, and both video recording backends. See <doc:VideoOutputGuide> for backend selection and <doc:RecorderGuide> for recording.

## Configure capture

Pass ordered ``Constraint`` values to the Camera initializer. Apply session and controller options through modifiers:

```swift
import SwiftUI
import VisionCamera

@MainActor
func camera(device: CameraDevice, photo: PhotoOutput, active: Bool) -> some View {
	Camera(
		device: device,
		isActive: active,
		outputs: [photo],
		constraints: [.frameRate(30)]
	)
	.mirrorMode(.auto)
	.resizeMode(.aspectFill)
	.orientationSource(.device)
	.sessionConfiguration(.init(allowsHapticsAndSystemSoundsPlayback: true))
}
```

Camera applies your constraints first, then a resolution-bias constraint for its preview, followed by one for each output in the supplied order. Explicit constraints therefore take precedence. Reordering outputs can change resolution negotiation. See <doc:Constraints>.

Changes to the device, output identities or order, constraints, mirroring, or session options reconfigure the session. Callback changes and view layout updates reuse the current configuration. Zoom, exposure, torch, and controller options use the current ``CameraController`` without rebuilding the connection graph.

Keep output options stable while the Camera owns their configuration. Replace an output when its construction options need to change. Do not configure the same outputs concurrently through a second Camera or native session.

## Update controls

Use `.zoom($zoom)` for two-way control between a SwiftUI binding and native pinch gestures. `.zoom(zoom)` supplies a fixed value and cannot be combined with the native zoom gesture. That invalid combination reports an error and keeps capture stopped until corrected. Omit the zoom modifier to let the gesture manage zoom internally.

Set exposure with `.exposureBias(value)` and the torch with `.torchMode(mode)`. Use `.initialZoom(value)` and `.initialExposureBias(value)` for initial device settings. Ongoing zoom and exposure values take precedence over initial values.

Apply low-light boost, smooth autofocus, and distortion correction with `.controllerConfiguration(...)`. These settings remain subject to device support and report failures through `.onError`.

Use `.onConfigured` to receive the current ``CameraController`` for custom focus, zoom animation, or other native operations. Keep that reference only while it belongs to the current configuration. A failed control adjustment reports an error separately and does not undo a successful session configuration. Use `.onPreviewChanged` to access the mounted ``PreviewView`` for metering or coordinate conversion, and clear your reference when the callback receives `nil`. The handler that receives the preview also receives its removal, even if a later update supplies a different closure. Keep its owner alive for the mounted Camera's lifetime.

## Own app lifecycle policy

Set `isActive` from your app's scene state and screen visibility. A mounted Camera with `isActive: false` stays configured for a later start. Removing the Camera stops capture, disconnects outputs, and removes its listeners, orientation updates, and gestures. Stop callbacks apply while mounted and do not fire after removal.

Camera serializes updates and waits for configuration before starting. If the view becomes inactive or disappears during configuration, an outdated request cannot start it afterward.

SwiftUI can keep a hidden tab or navigation screen mounted. Camera does not infer whether another view covers it. Compute `isActive` from the relevant navigation state as well as `scenePhase`. Permission prompts and recording policy also belong to the app. Stop or cancel a recording when your app's policy requires it before removing its output. See <doc:Lifecycle>.

## Handle events and orientation

Camera event closures run on the main actor. Use `.onConfigured` and `.didSelectConfiguration` for configuration, `.onStarted` and `.onStopped` for session activity, and `.onPreviewStarted` and `.onPreviewStopped` for preview activity. Session start and preview start are separate events.

Use `.onError`, `.onInterruptionStarted`, and `.onInterruptionEnded` to show capture problems in your UI. `.onSubjectAreaChanged` reports native subject-area changes. Callback replacement does not rebuild the session.

Capture orientation follows the device by default. `.orientationSource(.interface)` follows interface rotation. `.orientationSource(nil)` preserves orientations you assign to the outputs yourself. The preview always follows the interface. `.onUIRotationChanged` reports the relative rotation in degrees for controls that should follow capture orientation. Custom orientation does not emit this event because outputs can have different orientations. See <doc:Orientation>.

These main-actor guarantees apply to Camera's view events. Photo, video, and frame output callbacks retain their native delivery queues. Process Frames on their delivery queue and publish only the UI state your app needs.

## Use a custom session or renderer

For an app-owned session, ``CameraPreview`` displays a retained ``PreviewOutput`` without managing capture lifecycle. ``CameraFrameRenderer`` displays a retained ``FrameRenderer`` without publishing individual Frames through SwiftUI. See <doc:PreviewViewGuide> and <doc:FrameRendererViewGuide>.

Both adapters use [UIViewRepresentable](https://developer.apple.com/documentation/swiftui/uiviewrepresentable) to mount the existing UIKit views. Their update methods retain native object identity and their teardown methods detach the displayed layers. SwiftUI owns layout.

## Translate a React Native Camera

The SwiftUI API covers the iOS behavior of the React Native Camera through native types:

| React Native input | SwiftUI equivalent |
| --- | --- |
| `device`, `isActive`, `outputs`, `constraints` | Camera initializer values |
| `zoom`, `exposure`, `torchMode` | Zoom binding or value, exposure bias, and torch modifiers |
| `getInitialZoom`, `getInitialExposureBias` | Initial control modifiers |
| `mirrorMode`, `resizeMode`, `orientationSource` | Typed modifiers |
| `enableNativeZoomGesture`, `enableNativeTapToFocusGesture` | Gesture modifiers |
| Low-light boost, smooth autofocus, distortion correction | `CameraControllerConfiguration` |
| Background audio and haptics playback | `CameraSessionConfiguration` |
| Session, preview, interruption, subject-area, and rotation callbacks | Camera event closures |
| Imperative controller and coordinate methods | `onConfigured` and `onPreviewChanged` |
| Layout, hit testing, identity, and accessibility | Standard SwiftUI modifiers |

Native initial control values work directly. The React Native source declares `getInitialZoom` and `getInitialExposureBias`, but does not apply them. Custom orientation preserves supplied output values instead of the React implementation's fallback to `.up`. A SwiftUI zoom binding permits pinch gesture writeback.

Android preview implementation options and preview snapshots do not apply to iOS. React refs, shared values, and Nitro transport have no native equivalent or dependency.
