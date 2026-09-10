import SwiftUI
import VisionCamera

@MainActor
final class CameraModel: ObservableObject {
  // Outputs belong to this StateObject, so rendering the screen doesn't recreate them.
  let photoOutput = PhotoOutput()

  @Published private(set) var device: CameraDevice?
  @Published private(set) var videoOutput: (any VideoOutput)?
  @Published private(set) var recordingMode: RecordingMode = .standard
  @Published private(set) var status = "Preparing camera..."
  @Published private(set) var thumbnail: UIImage?
  @Published private(set) var isActive = false
  @Published private(set) var isConfigured = false
  @Published private(set) var isRunning = false
  @Published private(set) var isInterrupted = false
  @Published private(set) var isBusy = false
  @Published private(set) var isRecording = false
  @Published private(set) var isFinalizing = false
  @Published var zoom = 1.0

  private var microphoneGranted = false
  private var isPrepared = false
  private var isPreparing = false
  private var position: TargetCameraPosition = .back
  private var recorder: (any Recorder)?
  private var recordingID: UUID?
  private var isStartingRecording = false
  private var requestedActive = false
  private var sceneIsActive = false

  var controlsEnabled: Bool {
    return requestedActive && isActive && isConfigured && isRunning && !isInterrupted && !isBusy && !isFinalizing
  }

  var canSwitchCamera: Bool {
    return controlsEnabled && (!isRecording || recordingMode == .persistent)
  }

  func prepare() async {
    guard !isPrepared, !isPreparing else { return }
    isPreparing = true
    defer { isPreparing = false }
    do {
      guard try await VisionCamera.requestCameraPermission() else {
        status = "Camera access is denied. Enable it in Settings to use the example."
        return
      }
      microphoneGranted = try await VisionCamera.requestMicrophonePermission()
      guard let device = VisionCamera.defaultCamera(for: position) else {
        status = "No camera is available. Run this example on an iPhone or iPad."
        return
      }
      self.device = device
      setVideoOutput()
      isPrepared = true
      // Permission prompts can change the scene phase. Apply its latest value after preparation.
      await updateActive()
    } catch {
      report(error)
    }
  }

  func setActive(_ active: Bool) async {
    sceneIsActive = active
    await updateActive()
  }

  private func updateActive() async {
    // This example pauses capture outside the active scene and ends both recording backends.
    // Camera owns session start/stop; the app owns the recording policy.
    requestedActive = sceneIsActive && isPrepared
    if requestedActive {
      isActive = true
      return
    }
    // If start is still pending, toggleRecording submits the stop once it starts.
    guard !isStartingRecording else { return }
    await finishRecording()
    // A new scene activation may have arrived while the stop request was being submitted.
    if !requestedActive { isActive = false }
  }

  func didConfigure() {
    isConfigured = true
    showReadyStatus()
  }

  func didStart() {
    isRunning = true
    showReadyStatus()
  }

  func didStop() {
    isRunning = false
  }

  func didInterrupt(_ reason: InterruptionReason) {
    isInterrupted = true
    status = "Camera interrupted: \(reason)"
  }

  func didEndInterruption() {
    isInterrupted = false
    showReadyStatus()
  }

  func report(_ error: Error) {
    status = error.localizedDescription
  }

  func setRecordingMode(_ mode: RecordingMode) {
    guard controlsEnabled, !isRecording, recordingMode != mode else { return }
    recordingMode = mode
    setVideoOutput()
  }

  func switchCamera() {
    guard canSwitchCamera else { return }
    let nextPosition: TargetCameraPosition = position == .back ? .front : .back
    guard let nextDevice = VisionCamera.defaultCamera(for: nextPosition) else {
      status = "The other camera is unavailable."
      return
    }
    isConfigured = false
    position = nextPosition
    device = nextDevice
    zoom = 1
  }

  func capturePhoto() async {
    guard controlsEnabled else { return }
    isBusy = true
    defer { isBusy = false }
    do {
      let photo = try await photoOutput.capturePhoto()
      thumbnail = try await photo.image()
      status = "Photo captured"
    } catch {
      report(error)
    }
  }

  func toggleRecording() async {
    guard controlsEnabled else { return }
    if isRecording {
      await finishRecording()
      return
    }
    guard let output = videoOutput else { return }
    isBusy = true
    isStartingRecording = true
    defer {
      isBusy = false
      isStartingRecording = false
      if !requestedActive { isActive = false }
    }
    do {
      let recorder = try await output.makeRecorder()
      // The scene may have become inactive while the output prepared the recorder.
      guard requestedActive else { return }
      let id = UUID()
      self.recorder = recorder
      recordingID = id
      isRecording = true
      try await recorder.start(
        // Keep the model and recorder alive through finalization, even if the screen disappears.
        // recordingFinished releases the recorder and breaks this ownership relationship.
        onFinished: { result in
          DispatchQueue.main.async {
            self.recordingFinished(id: id, message: "Video saved: \(result.fileURL.lastPathComponent)")
          }
        },
        onError: { error in
          DispatchQueue.main.async {
            self.recordingFinished(id: id, message: error.localizedDescription)
          }
        },
        onPaused: nil,
        onResumed: nil
      )
      isStartingRecording = false
      guard recordingID == id else { return }
      if !requestedActive {
        await finishRecording()
      } else if !isFinalizing {
        status = "Recording"
      }
    } catch {
      if let id = recordingID {
        recordingFinished(id: id, message: error.localizedDescription)
      } else {
        report(error)
      }
    }
  }

  private func setVideoOutput() {
    isConfigured = false
    let options = VideoOutputOptions(isAudioEnabled: microphoneGranted)
    switch recordingMode {
    case .standard:
      videoOutput = MovieFileVideoOutput(options: options)
    case .persistent:
      videoOutput = VideoFrameOutput(options: options)
    }
  }

  private func finishRecording() async {
    guard let recorder, !isFinalizing, !isStartingRecording else { return }
    isFinalizing = true
    status = "Finishing video..."
    await recorder.stop()
    // Retain the recorder until its callback confirms that the file is finalized.
  }

  private func recordingFinished(id: UUID, message: String) {
    guard recordingID == id else { return }
    recorder = nil
    recordingID = nil
    isRecording = false
    isFinalizing = false
    status = message
  }

  private func showReadyStatus() {
    guard isConfigured, isRunning, !isRecording else { return }
    status = microphoneGranted ? "Ready" : "Ready. Microphone denied; video will be silent."
  }
}
