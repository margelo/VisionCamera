# Render frames in a view

Display individual Frame values with a native frame renderer.

``CameraFrameRenderer`` displays a ``FrameRenderer`` in SwiftUI. ``FrameRendererView`` provides the same display in UIKit.

## Mount a SwiftUI renderer

Pass a renderer retained by your processing owner. For a SwiftUI screen model, create that owner with `@StateObject`:

```swift
import SwiftUI
import VisionCamera

struct RenderedFrames: View {
	let renderer: FrameRenderer

	var body: some View {
		CameraFrameRenderer(renderer: renderer, resizeMode: .aspectFit)
	}
}
```

The adapter attaches the renderer's display layer, updates the resize mode, and detaches on removal. Send Frames directly to the renderer on one delivery queue. Keep Frames out of SwiftUI state.

## Mount a UIKit renderer

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

The processing owner also owns the frame callback. When processing ends, call `await output.setFrameHandler(nil)` on that owner before releasing it. Removing ``CameraFrameRenderer`` detaches the displayed layer. It does not replace or remove callbacks on outputs owned by your app.

Use one delivery queue for a renderer. The renderer enqueues native sample buffers directly; it does not apply the frame's relative orientation and mirror metadata for a custom presentation. Choose your output's physical rotation policy accordingly, or use ``Camera`` or ``PreviewView`` for a normal Camera preview.

See <doc:FrameOutputGuide> and <doc:Orientation>.

<!-- Adapted from react-native-vision-camera/docs/content/docs: nativeframerenderer-view. -->
