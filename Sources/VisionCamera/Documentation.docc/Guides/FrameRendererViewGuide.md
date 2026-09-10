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

For example, render frames streamed by a ``FrameOutput``:

```swift
import VisionCamera

func connectRenderer(output: FrameOutput, renderer: FrameRenderer) async {
	await output.setFrameHandler { frame in
		do {
			try renderer.render( frame)
		} catch {
			print("Could not render frame:", error)
		}
	}
}
```

The display layer retains an enqueued sample buffer, so the frame value can go out of scope after enqueueing.

Use one delivery queue for a renderer. The renderer enqueues native sample buffers directly; it does not apply the frame's relative orientation and mirror metadata for a custom presentation. Choose your output's physical rotation policy accordingly, or use ``PreviewView`` for a normal Camera preview.

See <doc:FrameOutputGuide> and <doc:Orientation>.

<!-- Adapted from react-native-vision-camera/docs/content/docs: nativeframerenderer-view. -->
