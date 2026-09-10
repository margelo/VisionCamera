# Render frames in a view

Display individual Frame values with a native frame renderer.

``FrameRendererView`` is a UIKit view that renders ``Frame`` values using a ``FrameRenderer``.

```swift
import VisionCamera

@MainActor
func makeRendererView() -> FrameRendererView {
	let view = FrameRendererView(frame: .zero)
	view.renderer = FrameRenderer()
	return view
}
```

## Render a Frame

For example, render frames streamed by a ``CameraFrameOutput``:

```swift
import VisionCamera

func connectRenderer(output: CameraFrameOutput, renderer: FrameRenderer) async {
	await output.setOnFrameCallback { frame in
		defer { frame.dispose() }
		do {
			try renderer.renderFrame(frame: frame)
		} catch {
			print("Could not render frame:", error)
		}
	}
}
```

The display layer retains an enqueued sample buffer, so the frame wrapper can be disposed after enqueueing.

Use one delivery queue for a renderer. The renderer enqueues native sample buffers directly; it does not apply the frame's relative orientation and mirror metadata for a custom presentation. Choose your output's physical rotation policy accordingly, or use ``PreviewView`` for a normal Camera preview.

See <doc:FrameOutput> and <doc:Orientation>.

<!-- Adapted from react-native-vision-camera/docs/content/docs: nativeframerenderer-view. -->
