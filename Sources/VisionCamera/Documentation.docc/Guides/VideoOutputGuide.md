# The video output

Capture videos, optionally with audio.

A ``VideoOutput`` allows capturing videos, optionally with audio from the microphone.

## Create a video output

Create a ``MovieFileVideoOutput`` and connect it to your session:

```swift
import VisionCamera

func prepareVideoCamera() async throws -> (CameraSession, any VideoOutput) {
	let session = CameraSession()
	let output = MovieFileVideoOutput()
	_ = try await session.configure(connections: [
		.init(input: .position(.back), outputs: [.init(output: output)])
	])
	await session.start()
	return (session, output)
}
```

Request Camera permission first, and retain the returned session and output. See ``VideoOutputOptions`` for configuration options.

### Enable audio

By default, audio is disabled. To record audio from the microphone, set `enableAudio` to `true`:

```swift
import VisionCamera

func makeVideoOutputWithAudio() -> any VideoOutput {
	return MovieFileVideoOutput(options: .init(enableAudio: true))
}
```

> Important: Recording audio requires microphone permission and an `NSMicrophoneUsageDescription` in your app's Info.plist. See <doc:GettingStarted>.

### Persistent video outputs

With ``MovieFileVideoOutput``, an active recording stops when the input Camera device changes, for example when the user flips from front to back. To continue recording while changing devices, use ``VideoFrameOutput``:

```swift
import VisionCamera

func makePersistentVideoOutput() -> any VideoOutput {
	return VideoFrameOutput(options: .init(enableAudio: true))
}
```

Retain and reconnect the same output when switching devices. ``VideoFrameOutput`` uses an `AVCaptureVideoDataOutput` and `AVAssetWriter` pipeline, which introduces additional processing. Use ``MovieFileVideoOutput`` when your app does not need recording across device changes. Both implement ``VideoOutput``.

### File container format

``MovieFileVideoOutput`` records QuickTime movies. Temporary files use a `.mov` extension; a custom destination path does not change the container. To record MPEG-4, use ``VideoFrameOutput`` with `fileType: .mp4`:

```swift
import VisionCamera

func makeMP4Output() -> any VideoOutput {
	return VideoFrameOutput(fileType: .mp4)
}
```

## Select a codec

Query the connected output for its native codecs, then select one before preparing the recorder:

```swift
import VisionCamera

func selectH264(output: any VideoOutput) async throws {
	if try output.getSupportedVideoCodecs().contains(.h264) {
		try await output.setVideoCodec(.h264)
	}
}
```

Codecs use AVFoundation's `AVVideoCodecType`, including HEVC, ProRes, and future codec identifiers. Availability depends on the device, selected format, container, and operating system. If no codec is selected, AVFoundation chooses the encoding settings. ProRes variants determine their own bit rates. ProRes RAW recording requires locked white balance before recorder preparation. After changing the camera or active format, recorder preparation rechecks codec availability.

## Prepare a recorder

Before recording a video, prepare a ``Recorder`` using `makeRecorder(settings:)`:

```swift
import VisionCamera

func prepareRecorder(output: any VideoOutput) async throws -> any Recorder {
	return try await output.makeRecorder()
}
```

Recorder preparation runs on the output's queue and can throw if encoding settings, audio input, or the destination file cannot be prepared. Both backends require a configured Camera connection before recorder preparation.

See <doc:RecorderGuide> to start, pause, resume, stop, or cancel the recording.

> Important: A recorder is single-use. Create a new recorder for each video.

<!-- Adapted from react-native-vision-camera/docs/content/docs/video-output.mdx. -->
