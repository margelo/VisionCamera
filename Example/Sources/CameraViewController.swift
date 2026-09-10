import UIKit
import VisionCamera

@MainActor
final class CameraViewController: UIViewController {
  private let camera = VisionCamera()
  private let preview = PreviewView()
  private let status = UILabel()
  private let thumbnail = UIImageView()
  private let photoButton = UIButton(type: .system)
  private let recordButton = UIButton(type: .system)
  private let switchButton = UIButton(type: .system)
  private let recordingMode = UISegmentedControl(items: ["Standard", "Persistent"])
  private var session: CameraSession?
  private var photoOutput: CameraPhotoOutput?
  private var videoOutput: (any CameraVideoOutput)?
  private var previewOutput: CameraPreviewOutput?
  private var recorder: (any Recorder)?
  private var controller: CameraController?
  private var recordingID: UUID?
  private var isFinalizing = false
  private var usesPersistentRecorder = false
  private var queuedOperations = 0
  private var isReady = false
  private var orientationManager: (any OrientationManager)?
  private var subscriptions: [ListenerSubscription] = []
  private var position: TargetCameraPosition = .back
  private var microphoneGranted = false
  private var setupStarted = false
  private var visible = false
  private var operation: Task<Void, Never>?

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .black
    status.textColor = .white
    status.numberOfLines = 0
    status.textAlignment = .center
    status.text = "Preparing camera..."
    thumbnail.contentMode = .scaleAspectFit
    thumbnail.backgroundColor = .black.withAlphaComponent(0.5)
    recordingMode.selectedSegmentIndex = 0
    recordingMode.addTarget(self, action: #selector(changeRecordingMode), for: .valueChanged)
    photoButton.setTitle("Photo", for: .normal)
    photoButton.addTarget(self, action: #selector(capturePhoto), for: .touchUpInside)
    recordButton.setTitle("Record", for: .normal)
    recordButton.addTarget(self, action: #selector(toggleRecording), for: .touchUpInside)
    switchButton.setTitle("Flip", for: .normal)
    switchButton.addTarget(self, action: #selector(switchCamera), for: .touchUpInside)
    let buttons = UIStackView(arrangedSubviews: [photoButton, recordButton, switchButton])
    buttons.distribution = .fillEqually
    let controls = UIStackView(arrangedSubviews: [status, recordingMode, buttons])
    controls.axis = .vertical
    controls.spacing = 12
    for subview in [preview, controls, thumbnail] {
      subview.translatesAutoresizingMaskIntoConstraints = false
      view.addSubview(subview)
    }
    NSLayoutConstraint.activate([
      preview.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      preview.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      preview.topAnchor.constraint(equalTo: view.topAnchor),
      preview.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      controls.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
      controls.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
      controls.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
      buttons.heightAnchor.constraint(equalToConstant: 48),
      thumbnail.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
      thumbnail.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
      thumbnail.widthAnchor.constraint(equalToConstant: 96),
      thumbnail.heightAnchor.constraint(equalToConstant: 128),
    ])
    NotificationCenter.default.addObserver(self, selector: #selector(updateLifecycle), name: UIApplication.didBecomeActiveNotification, object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(updateLifecycle), name: UIApplication.willResignActiveNotification, object: nil)
    refreshControls()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    visible = true
    if !setupStarted {
      setupStarted = true
      enqueue { try await self.setup() }
    } else {
      updateLifecycle()
    }
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    visible = false
    updateLifecycle()
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
    for subscription in subscriptions { subscription.remove() }
    try? orientationManager?.stopOrientationUpdates()
  }

  private func enqueue(_ action: @escaping @MainActor () async throws -> Void) {
    queuedOperations += 1
    refreshControls()
    let previous = operation
    operation = Task { [weak self] in
      await previous?.value
      guard let self else { return }
      defer {
        self.queuedOperations -= 1
        self.refreshControls()
      }
      do { try await action() } catch { self.status.text = error.localizedDescription }
    }
  }

  private func setup() async throws {
    guard try await camera.requestCameraPermission() else {
      status.text = "Camera access is denied. Enable it in Settings to use the example."
      return
    }
    microphoneGranted = try await camera.requestMicrophonePermission()
    let session = try camera.createCameraSession()
    self.session = session
    let previewOutput = camera.createPreviewOutput()
    self.previewOutput = previewOutput
    preview.previewOutput = previewOutput
    photoOutput = try camera.createPhotoOutput()
    subscriptions = [
      try session.addOnErrorListener { [weak self] error in
        DispatchQueue.main.async { self?.status.text = error.localizedDescription }
      },
      try session.addOnInterruptionStartedListener { [weak self] reason in
        DispatchQueue.main.async { self?.status.text = "Camera interrupted: \(reason)" }
      },
      try session.addOnInterruptionEndedListener { [weak self] in
        DispatchQueue.main.async { self?.updateLifecycle() }
      },
    ]
    try await configureVideoOutput()
    let manager = camera.createOrientationManager(orientationSource: .device)
    orientationManager = manager
    try manager.startOrientationUpdates { [weak self] orientation in
      DispatchQueue.main.async {
        self?.photoOutput?.outputOrientation = orientation
        self?.videoOutput?.outputOrientation = orientation
      }
    }
    try await applyLifecycle()
    status.text = microphoneGranted ? "Ready" : "Ready. Microphone denied; video will be silent."
    isReady = true
  }

  private func configureVideoOutput() async throws {
    videoOutput = camera.createVideoOutput(
      options: VideoOutputOptions(
        enableAudio: microphoneGranted,
        enablePersistentRecorder: recordingMode.selectedSegmentIndex == 1
      ))
    usesPersistentRecorder = videoOutput is CameraVideoFrameOutput
    if let orientation = orientationManager?.currentOrientation {
      videoOutput?.outputOrientation = orientation
    }
    try await configureSession()
  }

  private func configureSession() async throws {
    guard let session, let photoOutput, let videoOutput, let previewOutput else { return }
    let outputs: [any CameraOutput] = [photoOutput, videoOutput, previewOutput]
    let constraints: [Constraint] =
      [.fps(FPSConstraint(fps: 30))]
      + outputs.map {
        .resolutionBias(ResolutionBiasConstraint(resolutionBias: $0))
      }
    let controllers = try await session.configure(connections: [
      CameraSessionConnection(
        input: .position(position),
        outputs: outputs.map { CameraOutputConfiguration(output: $0) },
        constraints: constraints
      )
    ])
    let focus = camera.createTapToFocusGestureController()
    let zoom = camera.createZoomGestureController()
    controller = controllers.first
    focus.controller = controller
    zoom.controller = controller
    preview.gestureControllers = [focus, zoom]
  }

  @objc private func updateLifecycle() {
    enqueue { try await self.applyLifecycle() }
  }

  private func applyLifecycle() async throws {
    guard let session else { return }
    if visible && UIApplication.shared.applicationState == .active {
      try await session.start()
    } else {
      if recorder != nil && !isFinalizing { try await finishRecording() }
      try await session.stop()
    }
  }

  @objc private func capturePhoto() {
    enqueue {
      guard let output = self.photoOutput else { return }
      let photo = try await output.capturePhoto(settings: .init(), callbacks: .init())
      self.thumbnail.image = try await photo.toImageAsync()
      self.status.text = "Photo captured"
    }
  }

  @objc private func toggleRecording() {
    enqueue {
      if self.recorder != nil {
        if !self.isFinalizing { try await self.finishRecording() }
        return
      }
      guard let output = self.videoOutput else { return }
      let recorder = try await output.createRecorder(settings: .init())
      let id = UUID()
      self.recorder = recorder
      self.recordingID = id
      do {
        try await recorder.startRecording(
          onRecordingFinished: { [weak self] path, _ in
            DispatchQueue.main.async {
              self?.recordingFinished(id: id, message: "Video saved: \(URL(fileURLWithPath: path).lastPathComponent)")
            }
          },
          onRecordingError: { [weak self] error in
            DispatchQueue.main.async {
              self?.recordingFinished(id: id, message: error.localizedDescription)
            }
          },
          onRecordingPaused: nil,
          onRecordingResumed: nil
        )
        guard self.recordingID == id else { return }
        self.recordButton.setTitle("Stop", for: .normal)
        self.status.text = "Recording"
      } catch {
        self.recordingFinished(id: id, message: error.localizedDescription)
        throw error
      }
    }
  }

  private func finishRecording() async throws {
    guard let recorder else { return }
    isFinalizing = true
    refreshControls()
    status.text = "Finishing video..."
    do { try await recorder.stopRecording() } catch {
      isFinalizing = false
      throw error
    }
  }

  private func recordingFinished(id: UUID, message: String) {
    guard recordingID == id else { return }
    recorder = nil
    recordingID = nil
    isFinalizing = false
    recordButton.setTitle("Record", for: .normal)
    status.text = message
    refreshControls()
  }

  @objc private func switchCamera() {
    enqueue {
      guard !self.isFinalizing, self.recorder == nil || self.usesPersistentRecorder else {
        throw CameraError(message: "Use persistent recording to switch cameras while recording.")
      }
      self.position = self.position == .back ? .front : .back
      try await self.configureSession()
    }
  }

  @objc private func changeRecordingMode() {
    enqueue { try await self.configureVideoOutput() }
  }

  private func refreshControls() {
    let enabled = isReady && queuedOperations == 0 && visible
    photoButton.isEnabled = enabled && !isFinalizing
    recordButton.isEnabled = enabled && !isFinalizing
    switchButton.isEnabled = enabled && !isFinalizing && (recorder == nil || usesPersistentRecorder)
    recordingMode.isEnabled = enabled && recorder == nil
  }
}
