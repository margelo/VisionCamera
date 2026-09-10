# Location metadata

Add a caller-provided location to captured photos and videos.

Captured photos and videos can contain location tags in EXIF or video metadata. VisionCamera accepts a native `CLLocation` from your app.

## Obtain a location

Use Core Location in your app to request authorization and obtain a location. VisionCamera does not start location services or request location permission for you.

You can also construct a location directly for a known capture location:

```swift
import CoreLocation

let captureLocation = CLLocation(latitude: 48.2082, longitude: 16.3738)
```

## Add location to a photo

Pass the location in ``CapturePhotoSettings``:

```swift
import CoreLocation
import VisionCamera

func captureWithLocation(
	output: PhotoOutput,
	location: CLLocation
) async throws -> Photo {
	return try await output.capturePhoto(settings: .init(location: location))
}
```

## Add location to a video

Pass the location when creating the recorder:

```swift
import CoreLocation
import VisionCamera

func recorderWithLocation(
	output: any VideoOutput,
	location: CLLocation
) async throws -> any Recorder {
	return try await output.makeRecorder(settings: .init(location: location))
}
```

See <doc:PhotoOutputGuide> and <doc:RecorderGuide> for capture and recording.

<!-- Adapted from react-native-vision-camera/docs/content/docs: location. -->
