# Low light boost

Improve exposure in dark scenes with low light boost, binned formats, and lower frame rates.

Low light boost allows the Camera pipeline to automatically extend exposure times and effectively drop frame rate to receive more light, if necessary. This is useful in dark scenes where the image would otherwise look too dark.

## Enable low light boost

Each ``CameraDevice`` exposes whether it supports low light boost through `supportsLowLightBoost`:

```swift
import VisionCamera

func enableLowLightBoost(controller: CameraController) async throws {
	guard controller.device.supportsLowLightBoost else { return }
	try await controller.configure(config: .init(enableLowLightBoost: true))
}
```

Enabling low light boost on an unsupported device throws an error.

## Binned formats

Binned formats combine multiple neighboring sensor pixels into one larger effective pixel. This often improves low-light exposure too. If low-light performance is more important than maximum spatial detail, prefer a `.binned(.init(binned: true))` constraint.

## Lower FPS

Lower FPS gives the Camera more time to expose each Frame, which can improve low-light exposure. If you don't need 60 FPS, use a lower frame rate such as 30 FPS or 24 FPS. See <doc:FPS> and <doc:Constraints>.

## Exposure bias

Increasing <doc:ExposureBias> can also make the image brighter, but it may introduce more noise. If possible, prefer receiving more light through low light boost, binned formats, or lower FPS.

<!-- Adapted from react-native-vision-camera/docs/content/docs/low-light-boost.mdx. -->
