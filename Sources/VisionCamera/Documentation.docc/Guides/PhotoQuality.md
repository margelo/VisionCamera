# Configuring photo quality

Balance photo quality, compression, and capture speed.

While the ``CameraSession`` negotiates photo resolution based on your constraints and connected outputs, the ``PhotoOutput`` can still adjust compression quality and balance photo quality against capture speed.

## Adjust quality prioritization

Use `qualityPrioritization` to configure the capture mode. `.speed` prioritizes capture speed at the cost of image quality. `.quality` prioritizes photo quality and can introduce more latency. `.balanced` balances the two.

```swift
import VisionCamera

func makeQualityPhotoOutput() -> PhotoOutput {
	return PhotoOutput(options: .init(
		qualityPrioritization: .quality
	))
}
```

When no quality prioritization is specified, AVFoundation uses balanced prioritization for processed photos and speed for Bayer RAW. Bayer RAW rejects an explicit balanced or quality preference. ProRAW supports quality prioritization.

Support depends on the output configuration and device. A speed preference does not guarantee zero shutter lag on every device or OS version.

## Configure compression quality

Processed formats such as JPEG and HEIC compress captured photos. The default quality is `0.9`. To request maximum compression quality, set it to `1`:

```swift
import VisionCamera

func makeJPEGOutput() -> PhotoOutput {
	return PhotoOutput(options: .init(
		containerFormat: .jpeg(quality: 1),
		qualityPrioritization: .balanced
	))
}
```

A lower value such as `0.7` can produce smaller files with more compression artifacts. Compression quality is separate from resolution and capture prioritization.

> Note: `.dng` has no processed-image compression quality parameter. See <doc:RawPhotos>.

<!-- Adapted from react-native-vision-camera/docs/content/docs/photo-quality.mdx. -->
