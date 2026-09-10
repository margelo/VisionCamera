// Copyright © 2026 Marc Rousavy @ Margelo

import UIKit

#if USE_VISIONCAMERA
  import VisionCamera
#endif
#if USE_VISIONCAMERARESIZER
  import VisionCameraResizer
#endif
#if USE_VISIONCAMERABARCODESCANNER
  import VisionCameraBarcodeScanner
#endif
#if USE_VISIONCAMERALOCATION
  import VisionCameraLocation
#endif

@MainActor
final class OptionalModulesViewController: UIViewController {
  private let status = UILabel()
  #if USE_VISIONCAMERA
    private let previewView = PreviewView()
    private let session = CameraSession()
    private let frames = FrameOutput(options: .init(pixelFormat: .yuv))
    private var configured = false
    private var cameraTask: Task<Void, Never>?
  #endif
  #if USE_VISIONCAMERALOCATION
    private var locationManager: LocationManager?
  #endif

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .systemBackground
    status.text = "Select a feature to begin."
    status.numberOfLines = 0
    let stack = UIStackView(arrangedSubviews: [status])
    stack.axis = .vertical
    stack.spacing = 16
    stack.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(stack)
    NSLayoutConstraint.activate([
      stack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
      stack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
      stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
    ])
    #if USE_VISIONCAMERA
      previewView.heightAnchor.constraint(equalToConstant: 320).isActive = true
      stack.addArrangedSubview(previewView)
      let cameraButton = UIButton(type: .system)
      cameraButton.setTitle("Start Camera", for: .normal)
      cameraButton.addAction(UIAction { [weak self] _ in self?.startCamera() }, for: .touchUpInside)
      stack.addArrangedSubview(cameraButton)
    #endif
    #if USE_VISIONCAMERALOCATION
      let locationButton = UIButton(type: .system)
      locationButton.setTitle("Enable location", for: .normal)
      locationButton.addAction(UIAction { [weak self] _ in self?.enableLocation() }, for: .touchUpInside)
      stack.addArrangedSubview(locationButton)
    #endif
  }

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    #if USE_VISIONCAMERA
      cameraTask?.cancel()
      Task {
        await frames.setOnFrameCallback(onFrame: nil)
        await session.stop()
      }
    #endif
    #if USE_VISIONCAMERALOCATION
      locationManager?.stopUpdating()
      locationManager = nil
    #endif
  }

  #if USE_VISIONCAMERA
    private func startCamera() {
      guard cameraTask == nil else { return }
      cameraTask = Task {
        defer { cameraTask = nil }
        do {
          guard try await VisionCamera.requestCameraPermission() else {
            status.text = "Camera permission was denied."
            return
          }
          try Task.checkCancellation()
          if !configured {
            let preview = PreviewOutput()
            previewView.previewOutput = preview
            _ = try await session.configure(connections: [
              CameraSessionConnection(
                input: .position(.back),
                outputs: [CameraOutputConfiguration(output: preview), CameraOutputConfiguration(output: frames)])
            ])
            configured = true
          }
          try Task.checkCancellation()
          let processor = try ExampleFrameProcessor()
          await frames.setOnFrameCallback { [weak self] frame in
            defer { frame.dispose() }
            guard let message = processor.process(frame) else { return }
            DispatchQueue.main.async { [weak self] in self?.status.text = message }
          }
          try Task.checkCancellation()
          await session.start()
          if Task.isCancelled {
            await frames.setOnFrameCallback(onFrame: nil)
            await session.stop()
          }
        } catch {
          await frames.setOnFrameCallback(onFrame: nil)
          status.text = error.localizedDescription
        }
      }
    }
  #endif

  #if USE_VISIONCAMERALOCATION
    private func enableLocation() {
      do {
        if locationManager == nil {
          let manager = try LocationManager()
          manager.onLocationChanged = { [weak self] location in
            self?.status.text = "Location: \(location.coordinate.latitude), \(location.coordinate.longitude)"
          }
          manager.onError = { [weak self] error in self?.status.text = error.localizedDescription }
          manager.onAuthorizationChanged = { [weak self, weak manager] authorization, _ in
            guard self?.viewIfLoaded?.window != nil else { return }
            guard authorization == .authorizedWhenInUse || authorization == .authorizedAlways else { return }
            do {
              try manager?.startUpdating()
            } catch {
              self?.status.text = error.localizedDescription
            }
          }
          locationManager = manager
        }
        try locationManager?.requestWhenInUseAuthorization()
        if let manager = locationManager,
          manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways
        {
          try manager.startUpdating()
        }
      } catch {
        status.text = error.localizedDescription
      }
    }
  #endif
}
