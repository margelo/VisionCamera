import AVFoundation
import UIKit
import VisionCamera
import XCTest

final class PublicAPITests: XCTestCase {
  private var defaultBackCamera: CameraDevice? { VisionCamera.defaultCamera(for: .back) }

  func testStaticCameraQueriesDoNotRequireAFactoryInstance() {
    XCTAssertTrue(PermissionStatus.allCases.contains(VisionCamera.cameraPermissionStatus))
    XCTAssertTrue(PermissionStatus.allCases.contains(VisionCamera.microphonePermissionStatus))
    XCTAssertEqual(VisionCamera.supportsMultiCamSessions, AVCaptureMultiCamSession.isMultiCamSupported)
    XCTAssertNil(VisionCamera.camera(withID: "VisionCameraTests.missing-camera.\(UUID())"))
    if let camera = defaultBackCamera {
      XCTAssertEqual(camera.position, .back)
      let copy = CameraDevice(device: camera.device)
      XCTAssertEqual(camera, copy)
      XCTAssertEqual(Set([camera, copy]).count, 1)
    }

    let observation = VisionCamera.observeCameraDevices { _ in }
    observation.cancel()
  }

  func testDefaultSessionConstructionIsInfallibleAndDoesNotStartCapture() {
    let session = CameraSession()
    XCTAssertFalse(session.isRunning)
    XCTAssertFalse(session.session is AVCaptureMultiCamSession)
    XCTAssertTrue(session.session.inputs.isEmpty)
    XCTAssertTrue(session.session.outputs.isEmpty)
  }

  func testExplicitSingleCameraSessionDoesNotRequireMultiCameraSupport() throws {
    let session = try CameraSession(isMultiCamEnabled: false)
    XCTAssertFalse(session.session is AVCaptureMultiCamSession)
    XCTAssertFalse(session.isRunning)
  }

  func testMultiCameraInitializerValidatesPlatformSupport() throws {
    if VisionCamera.supportsMultiCamSessions {
      let session = try CameraSession(isMultiCamEnabled: true)
      XCTAssertTrue(session.session is AVCaptureMultiCamSession)
      XCTAssertFalse(session.isRunning)
    } else {
      XCTAssertThrowsError(try CameraSession(isMultiCamEnabled: true)) { error in
        guard case .multiCamUnsupported? = error as? ConfigurationError else {
          return XCTFail("Expected the unsupported-multicam configuration error")
        }
      }
    }
  }

  @MainActor
  func testDirectOutputInitializersApplyDefaultsAndSelectTheRecordingBackend() async {
    let preview = PreviewOutput()
    let photo = PhotoOutput()
    let frame = FrameOutput()
    let depth = DepthOutput()
    let movie = MovieFileVideoOutput()
    let persistent = VideoFrameOutput()
    let objects = ObjectOutput(options: ObjectOutputOptions(enabledObjectTypes: [.qr]))
    let outputs: [any CameraOutput] = [preview, photo, frame, depth, movie, persistent, objects]

    XCTAssertEqual(outputs.map(\.mediaType), [.video, .video, .video, .depth, .video, .video, .metadata])
    XCTAssertEqual(photo.output.maxPhotoQualityPrioritization, .balanced)
    XCTAssertTrue(frame.output.alwaysDiscardsLateVideoFrames)
    XCTAssertTrue(depth.output.alwaysDiscardsLateDepthData)
    XCTAssertTrue(depth.output.isFilteringEnabled)
    XCTAssertFalse(movie.requiresAudioInput)
    XCTAssertFalse(persistent.output.alwaysDiscardsLateVideoFrames)

    let previewView = PreviewView(output: preview)
    XCTAssertTrue(previewView.output === preview)
  }

  func testNormalizedMeteringPointUsesThePublicDefaultSize() {
    let point = MeteringPoint(location: CGPoint(x: 0.25, y: 0.75))
    XCTAssertEqual(point.size, 0.1)
    XCTAssertEqual(point.location, CGPoint(x: 0.25, y: 0.75))
  }

  @MainActor
  func testPreviewMeteringRequiresAnAttachedOutput() async {
    let preview = PreviewView()
    do {
      _ = try preview.meteringPoint(at: CGPoint(x: 100, y: 50))
      XCTFail("An unattached preview cannot convert metering coordinates")
    } catch PreviewError.outputNotAttached {
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }

  @MainActor
  func testPreviewMeteringRejectsInvalidViewRadius() async {
    let preview = PreviewView(output: PreviewOutput())
    for radius: CGFloat in [-1, .infinity, .nan] {
      do {
        _ = try preview.meteringPoint(at: .zero, size: radius)
        XCTFail("An invalid metering radius must fail")
      } catch PreviewError.invalidMeteringRadius(let invalid) {
        if radius.isNaN { XCTAssertTrue(invalid.isNaN) } else { XCTAssertEqual(invalid, radius) }
      } catch {
        XCTFail("Unexpected error: \(error)")
      }
    }
  }

  func testOutputSynchronizerReportsDisconnectedOutputIndex() {
    XCTAssertThrowsError(try OutputSynchronizer(outputs: [])) { error in
      guard case .insufficientSynchronizedOutputs(let count)? = error as? CaptureError else {
        return XCTFail("Expected the synchronized-output count")
      }
      XCTAssertEqual(count, 0)
    }
    XCTAssertThrowsError(try OutputSynchronizer(outputs: [FrameOutput(), DepthOutput()])) { error in
      guard case .synchronizedOutputNotConnected(let index)? = error as? CaptureError else {
        return XCTFail("Expected the disconnected-output index")
      }
      XCTAssertEqual(index, 0)
    }
  }

  func testFrameVideoRecorderPreparationRequiresAConnection() async {
    let output: any VideoOutput = VideoFrameOutput()
    do {
      _ = try await output.makeRecorder()
      XCTFail("Preparing a frame recorder requires a Camera connection")
    } catch RecordingError.outputNotConnected {
    } catch {
      XCTFail("Unexpected error: \(error)")
    }
  }

  func testCancelledRecorderPreparationStopsBeforeNativeSetup() async {
    let outputs: [any VideoOutput] = [MovieFileVideoOutput(), VideoFrameOutput()]
    for output in outputs {
      let task = Task { () async throws -> Void in
        withUnsafeCurrentTask { $0?.cancel() }
        _ = try await output.makeRecorder()
      }
      do {
        try await task.value
        XCTFail("Cancelled recorder preparation must not succeed")
      } catch {
        XCTAssertTrue(error is CancellationError)
      }
    }
  }

  func testMovieFileRecorderPreparesWithoutAConnectionButCannotStart() async throws {
    let output: any VideoOutput = MovieFileVideoOutput()
    let recorder = try await output.makeRecorder()
    let initialStatus = try await recorder.status()
    XCTAssertFalse(initialStatus.isRecording)
    XCTAssertFalse(initialStatus.isPaused)
    XCTAssertEqual(initialStatus.fileSize, 0)
    XCTAssertTrue(recorder.fileURL.isFileURL)
    XCTAssertEqual(recorder.fileURL.pathExtension, "mov")
    XCTAssertFalse(FileManager.default.fileExists(atPath: recorder.fileURL.path))

    do {
      try await recorder.start(
        onFinished: { _ in XCTFail("A disconnected recording cannot finish") },
        onError: { _ in XCTFail("An error before recording starts must be thrown") })
      XCTFail("A disconnected movie-file recorder cannot start")
    } catch RecordingError.outputNotConnected {
    }
    let status = try await recorder.status()
    XCTAssertFalse(status.isRecording)
    XCTAssertFalse(FileManager.default.fileExists(atPath: recorder.fileURL.path))
  }

  func testConcreteVideoOutputPreservesRecorderType() async throws {
    let recorder: VideoRecorder = try await MovieFileVideoOutput().makeRecorder()
    let status = await recorder.status()
    XCTAssertFalse(status.isRecording)
  }

  func testDirectConstraintsKeepExplicitPrioritiesAheadOfOutputResolution() {
    let output = PhotoOutput()
    let connection = CameraSessionConnection(
      input: .position(.back), outputs: [.init(output: output)],
      constraints: [.frameRate(60), .videoStabilization(.cinematic), .resolution(output)])
    guard case .frameRate(let frameRate) = connection.constraints[0],
      case .videoStabilization(let stabilization) = connection.constraints[1],
      case .resolution(let targetOutput) = connection.constraints[2]
    else { return XCTFail("Connection constraints changed order or payload") }
    XCTAssertEqual(frameRate, 60)
    XCTAssertEqual(stabilization, .cinematic)
    XCTAssertTrue(targetOutput === output)
  }
}
