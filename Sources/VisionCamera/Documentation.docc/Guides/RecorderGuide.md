# The recorder

Start, pause, resume, and stop a video recording.

A ``Recorder`` records video and audio data to a file. It is usually created by a ``CameraVideoOutput``. See <doc:VideoOutput> for preparing that output.

## Set a maximum duration or file size

To stop automatically when a duration or file size is reached, use `maxDuration` in seconds or `maxFileSize` in bytes:

```swift
import VisionCamera

func prepareLimitedRecorder(output: any CameraVideoOutput) async throws -> any Recorder {
	return try await output.createRecorder(settings: .init(
		maxDuration: 30,
		maxFileSize: 50_000_000
	))
}
```

When a limit is reached, the `onRecordingFinished` callback receives a corresponding ``RecordingFinishedReason``.

## Start recording

`startRecording` takes callbacks for recording events:

```swift
import Foundation
import VisionCamera

func beginRecording(recorder: any Recorder) async throws {
	try await recorder.startRecording(
		onRecordingFinished: { filePath, reason in
			let url = URL(fileURLWithPath: filePath)
			print("Saved video:", url, "Reason:", reason)
		},
		onRecordingError: { error in
			print("Recording failed:", error)
		},
		onRecordingPaused: { print("Recording paused") },
		onRecordingResumed: { print("Recording resumed") }
	)
}
```

The method returns when recording starts. An error before recording starts is thrown to the caller. Later failures arrive through `onRecordingError`. Callbacks run on the recording backend's queue. Dispatch UIKit changes to the main queue.

### Inspect progress

As a recording progresses, inspect `recordedDuration` and `recordedFileSize`. The recorder also exposes `isRecording`, `isPaused`, and `filePath`.

File paths are plain filesystem paths. Use `URL(fileURLWithPath:)` when an API expects a URL. Encoder buffering can cause the file size on disk to lag behind captured data.

## Pause and resume

Call `pauseRecording()` or `resumeRecording()` to pause or resume. The corresponding callback reports the transition:

```swift
import VisionCamera

func pause(recorder: any Recorder) async throws {
	try await recorder.pauseRecording()
}

func resume(recorder: any Recorder) async throws {
	try await recorder.resumeRecording()
}
```

The default movie-file backend requires iOS 18 or later for pausing and resuming. The persistent frame-based backend supports these operations on earlier deployment targets. Unsupported operations throw an error.

## Stop recording

To finish a recording, call `stopRecording()`:

```swift
import VisionCamera

func finish(recorder: any Recorder) async {
	await recorder.stopRecording()
}
```

This method returns once the stop is requested. It can take additional frames, or longer under thermal pressure, before the video file is finalized. Wait for `onRecordingFinished` before reading or sharing the completed file.

## Cancel recording

To cancel a recording, call `cancelRecording()`. Cancellation deletes the file and suppresses recording completion callbacks:

```swift
import VisionCamera

func cancel(recorder: any Recorder) async throws {
	try await recorder.cancelRecording()
}
```

## Interruptions

An incoming call, backgrounding the app, or a pipeline interruption can affect a recording. Observe the session's interruption listeners and the recorder's event callbacks. Do not assume recording can continue through every interruption.

By default, changing the input device stops an active recording. To continue recording across a device change, use the persistent output described in <doc:VideoOutput>.

## Create a new recorder

A recorder is single-use. After finishing or cancelling a recording, create a new recorder to record another video.

<!-- Adapted from react-native-vision-camera/docs/content/docs/recorder.mdx. -->
