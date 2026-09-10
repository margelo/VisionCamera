# Configuring photo quality

Balance photo quality, compression, and capture speed.

While the ``CameraSession`` negotiates photo resolution based on your constraints and connected outputs, the ``CameraPhotoOutput`` can still adjust compression quality and balance photo quality against capture speed.

## Adjust quality prioritization

Use `qualityPrioritization` to configure the capture mode. `.speed` prioritizes capture speed at the cost of image quality. `.quality` prioritizes photo quality and can introduce more latency. `.balanced` balances the two.

```swift
import VisionCamera

func makeQualityPhotoOutput() -> CameraPhotoOutput {
	return VisionCamera().createPhotoOutput(options: .init(
		qualityPrioritization: .quality
	))
}
```

Support depends on the output configuration and device. A speed preference does not guarantee zero shutter lag on every device or OS version.

## Configure compression quality

Processed formats such as JPEG and HEIC compress captured photos. The default quality is `0.9`. To request maximum compression quality, set it to `1`:

```swift
import VisionCamera

func makeJPEGOutput() -> CameraPhotoOutput {
	return VisionCamera().createPhotoOutput(options: .init(
		containerFormat: .jpeg,
		quality: 1,
		qualityPrioritization: .balanced
	))
}
```

A lower value such as `0.7` can produce smaller files with more compression artifacts. Compression quality is separate from resolution and capture prioritization.

> Note: RAW DNG capture does not use this processed-image compression quality setting. See <doc:RawPhotos>.

<!-- Adapted from react-native-vision-camera/docs/content/docs/photo-quality.mdx. -->
