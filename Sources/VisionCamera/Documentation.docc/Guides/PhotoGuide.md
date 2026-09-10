# A photo

Display, save, and inspect an in-memory photo.

A ``Photo`` is a RAW or processed in-memory capture from a ``PhotoOutput``. See <doc:PhotoOutputGuide> for capturing photos.

## Display a photo

A photo can be converted to a `UIImage` entirely in memory using `image()`:

```swift
import UIKit
import VisionCamera

@MainActor
func displayPhoto(_ photo: Photo, in imageView: UIImageView) async throws {
	imageView.image = try await photo.image()
}
```

RAW photos cannot be converted with this method. Use a RAW-capable image pipeline to develop the captured data.

## Release a photo

``Photo`` is a value that retains its native image data. Swift releases that data when no photo values or native references keep it alive. Avoid retaining large collections of in-memory photos after you have saved or displayed them.

## Save to a file

Use `writeToTemporaryFile()` or `write(to:options:)`:

```swift
import Foundation
import VisionCamera

func savePhoto(_ photo: Photo, to url: URL) async throws {
	try await photo.write(to: url)
}

func saveTemporaryPhoto(_ photo: Photo) async throws -> URL {
	return try await photo.writeToTemporaryFile()
}
```

To add a saved photo to the user's photo library, use Apple's Photos framework and request the corresponding photo-library authorization in your app.

## Container formats

Photos can be captured in different container formats, which adjust the capture pipeline's processing steps accordingly. DNG is a RAW format. JPEG and HEIC are processed formats that can apply color processing, compression, and multi-frame processing.

Inspect the captured format through `containerFormat`. See <doc:RawPhotos> and <doc:PhotoQuality>.

## Access the pixel buffer

Some photos expose a native `CVPixelBuffer` without decoding. This is commonly available for RAW photos. Read the optional `pixelBuffer` property to see whether pixels are available:

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

Use `encodedData()`, for example to upload the photo entirely in memory:

```swift
import Foundation
import VisionCamera

func encodedPhoto(_ photo: Photo) async throws -> Data {
	return try await photo.encodedData()
}
```

<!-- Adapted from react-native-vision-camera/docs/content/docs/a-photo.mdx. -->
