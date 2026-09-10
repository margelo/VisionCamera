# A photo

Display, save, and inspect an in-memory photo.

A ``Photo`` is a RAW or processed in-memory capture from a ``CameraPhotoOutput``. See <doc:PhotoOutput> for capturing photos.

## Display a photo

A photo can be converted to a `UIImage` entirely in memory using `toImageAsync()`:

```swift
import UIKit
import VisionCamera

@MainActor
func displayPhoto(_ photo: Photo, in imageView: UIImageView) async throws {
	imageView.image = try await photo.toImageAsync()
}
```

RAW photos cannot be converted with this method. Use a RAW-capable image pipeline to develop the captured data.

## Release a photo

Swift's automatic reference counting releases a photo when no references remain. There is no `dispose()` method on ``Photo``. Avoid retaining large collections of in-memory photos after you have saved or displayed them.

## Save to a file

Use `saveToTemporaryFileAsync()` or `saveToFileAsync(path:)`:

```swift
import Foundation
import VisionCamera

func savePhoto(_ photo: Photo, to url: URL) async throws {
	try await photo.saveToFileAsync(path: url.path)
}

func saveTemporaryPhoto(_ photo: Photo) async throws -> URL {
	let path = try await photo.saveToTemporaryFileAsync()
	return URL(fileURLWithPath: path)
}
```

To add a saved photo to the user's photo library, use Apple's Photos framework and request the corresponding photo-library authorization in your app.

## Container formats

Photos can be captured in different container formats, which adjust the capture pipeline's processing steps accordingly. DNG is a RAW format. JPEG and HEIC are processed formats that can apply color processing, compression, and multi-frame processing.

Inspect the captured format through `containerFormat`. See <doc:RawPhotos> and <doc:PhotoQuality>.

## Access the pixel buffer

Some photos expose a native `CVPixelBuffer` without decoding. This is commonly available for RAW photos. Check `hasPixelBuffer` or the optional `pixelBuffer` property before requesting it:

```swift
import CoreVideo
import VisionCamera

func photoPixelBuffer(_ photo: Photo) -> CVPixelBuffer? {
	return photo.pixelBuffer
}
```

A photo's pixel buffer contains pixels. It does not contain JPEG or HEIC container headers or EXIF metadata. A retained `CVPixelBuffer` remains alive independently of the photo wrapper.

## Access encoded image data

A photo also provides its encoded image data, including container metadata and EXIF flags. This is the data written when the photo is saved to a file.

Use `getFileDataAsync()`, for example to upload the photo entirely in memory:

```swift
import Foundation
import VisionCamera

func encodedPhoto(_ photo: Photo) async throws -> Data {
	return try await photo.getFileDataAsync()
}
```

<!-- Adapted from react-native-vision-camera/docs/content/docs/a-photo.mdx. -->
