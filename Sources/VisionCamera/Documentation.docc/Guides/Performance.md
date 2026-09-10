# Performance

Choose Camera settings that match your app's resolution, latency, and processing needs.

Camera configuration affects startup time, bandwidth, memory use, and processing latency. This guide covers common ways to improve Camera performance.

## Choose a simpler device

Selecting a Camera device with fewer constituent physical devices can reduce initialization work. Prefer a physical wide-angle Camera over a triple Camera when your app does not need automatic lens switching. See <doc:CameraDevices>.

## Use HDR and stabilization when needed

Video HDR uses higher bit-depth formats or additional processing. Stabilization buffers frames and adds latency. Leave these features disabled when they do not serve your capture requirements.

See <doc:VideoHDR> and <doc:VideoStabilization>.

## Avoid unnecessary pixel conversion

Requesting RGB often makes the pipeline convert native YUV buffers and use more memory. If your processing accepts YUV or native buffers, pass those directly. See <doc:PixelFormats>.

If your processing accepts orientation and mirroring metadata, keep physical buffer rotation disabled. See <doc:Orientation>.

## Choose the native object output for scanning

Use <doc:ObjectOutputGuide> when AVFoundation's supported object types meet your needs. It avoids adding a separate frame processing algorithm for those objects.

Only enable the code formats you actually need to scan.

## Attach only needed outputs

Each connected output can add processing and bandwidth requirements. Attach only the outputs your current Camera screen needs.

Use ``Camera`` in SwiftUI or a ``PreviewView`` in UIKit for a regular Camera preview. A custom frame renderer is useful when your app needs to render individual frames, but creates additional work in the frame path.

## Preserve SwiftUI object identity

Keep outputs and renderers in a model owned by `@StateObject`. Constructing them inside `body` replaces native objects on every evaluation and can trigger session reconfiguration. ``Camera`` preserves its session and preview across view updates and compares configuration values before touching the session.

Send streamed Frames directly to processing or a ``FrameRenderer``. Publishing each Frame as SwiftUI state needlessly updates the view hierarchy. See <doc:FrameRendererViewGuide>.

## Retain the session between uses

Stop a session when capture is inactive, then start it again when needed. Keeping the same configured session avoids rebuilding the entire Camera configuration each time a screen becomes visible. See <doc:Lifecycle>.

## Prefer faster photo settings when appropriate

Use `.speed` quality prioritization when capture speed matters more than maximum photo quality. See <doc:PhotoQuality>.

### Prepare photo settings

Some captures require the native Camera pipeline to allocate additional buffers or prepare parts of the photo processing path. This can matter for maximum-resolution photos, RAW, depth data, flash, or `.quality` prioritization.

If you know which settings you will use, prepare them before capture:

```swift
import VisionCamera

func prepareAndCapture(output: PhotoOutput) async throws -> Photo {
	let settings = CapturePhotoSettings(flashMode: .off)
	try await output.prepareSettings(settings: [settings])
	return try await output.capturePhoto(settings: settings)
}
```

Preparing settings is optional. It gives the native pipeline an opportunity to prepare for your expected capture.

## Choose an appropriate resolution

If your backend only accepts 1080p video, capturing 4K and resizing later adds avoidable work. Set an appropriate `targetResolution` and resolution-bias constraint. See <doc:Constraints>.

Binned formats combine neighboring sensor pixels. This reduces bandwidth and can improve low-light sensitivity, at the cost of fine detail. Prefer a binned format when that tradeoff suits your app.

## Choose an appropriate frame rate

Higher frame rates require more processing and bandwidth. If your app needs 30 FPS, do not request 60 FPS. See <doc:FPS>.

Keep frame processing within its time budget, release buffers promptly, and avoid queues that accumulate frames. See <doc:AsyncFrameProcessing>.

<!-- Adapted from react-native-vision-camera/docs/content/docs: performance. -->
