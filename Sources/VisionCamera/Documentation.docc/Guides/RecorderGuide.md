# The recorder

Start, pause, resume, and stop a video recording.

A ``Recorder`` records video and audio data to a file. It is usually created by a ``VideoOutput``. See <doc:VideoOutputGuide> for preparing that output.

## Set a maximum duration or file size

To stop automatically when a duration or file size is reached, use a `CMTime` for `maxDuration` or an integer byte count for `maxFileSize`:

```swift
import VisionCamera

func prepareLimitedRecorder(output: any VideoOutput) async throws -> any Recorder {
	return try await output.makeRecorder(settings: .init(
		maxDuration: .init(seconds: 30, preferredTimescale: 600),
		maxFileSize: 50_000_000
	))
}
```

When a limit is reached, the `onFinished` callback receives a ``RecordingResult`` with the corresponding ``RecordingFinishedReason``.

## Start recording

`start` takes callbacks for recording events:

```swift
import Foundation
import VisionCamera

func beginRecording(recorder: any Recorder) async throws {
	try await recorder.start(
		onFinished: { result in
			print("Saved video:", result.fileURL, "Reason:", result.reason)
		},
		onError: { error in
			print("Recording failed:", error)
		},
		onPaused: { print("Recording paused") },
		onResumed: { print("Recording resumed") }
	)
}
```

The method returns when recording starts. An error before recording starts is thrown to the caller. Later failures arrive through `onError`. Callbacks run on the recording backend's queue. Dispatch UIKit changes to the main queue.

### Inspect progress

Read a ``RecordingStatus`` snapshot with `try await recorder.status()`. The snapshot includes `isRecording`, `isPaused`, `duration`, and `fileSize`. The query runs on the recorder's queue, including any file-system work needed to read the file size.

```swift
import VisionCamera

func printProgress(recorder: any Recorder) async throws {
	let status = try await recorder.status()
	print(status.duration.seconds, "seconds,", status.fileSize, "bytes")
}
```

The recorder's `fileURL` is its destination. Encoder buffering can cause the file size on disk to lag behind captured data. A file that has not been created yet reports zero bytes. Other file-system errors propagate to the caller.

## Pause and resume

Call `pause()` or `resume()` to pause or resume. The corresponding callback reports the transition:

```swift
import VisionCamera

func pause(recorder: any Recorder) async throws {
	try await recorder.pause()
}

func resume(recorder: any Recorder) async throws {
	try await recorder.resume()
}
```

The default movie-file backend requires iOS 18 or later for pausing and resuming. The persistent frame-based backend supports these operations on earlier deployment targets. Unsupported operations throw an error.

## Stop recording

To finish a recording, call `stop()`:

```swift
import VisionCamera

func finish(recorder: any Recorder) async {
	await recorder.stop()
}
```

This method returns once the stop is requested. It can take additional frames, or longer under thermal pressure, before the video file is finalized. Wait for `onFinished` before reading or sharing the completed file.

## Cancel recording

To cancel a recording, call `cancel()`. Cancellation deletes the file and suppresses recording completion callbacks:

```swift
import VisionCamera

func cancel(recorder: any Recorder) async throws {
	try await recorder.cancel()
}
```

## Interruptions

An incoming call, backgrounding the app, or a pipeline interruption can affect a recording. Observe the session's interruption listeners and the recorder's event callbacks. Do not assume recording can continue through every interruption.

By default, changing the input device stops an active recording. To continue recording across a device change, use the persistent output described in <doc:VideoOutputGuide>.

## Create a new recorder

A recorder is single-use. After finishing or cancelling a recording, create a new recorder to record another video.

<!-- Adapted from react-native-vision-camera/docs/content/docs/recorder.mdx. -->
