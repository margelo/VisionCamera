import AVFoundation
import UIKit
import VisionCamera
import XCTest

final class PublicAPITests: XCTestCase {
  private var defaultBackCamera: CameraDevice? { VisionCamera.defaultCamera(for: .back) }

  func testStaticCameraQueriesDoNotRequireAFactoryInstance() {
    XCTAssertEqual(VisionCamera.cameraPermissionStatus, AVCaptureDevice.authorizationStatus(for: .video))
    XCTAssertEqual(VisionCamera.microphonePermissionStatus, AVCaptureDevice.authorizationStatus(for: .audio))
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

  func testNormalizedMeteringPointPreservesNativeLocation() {
    let point = MeteringPoint(location: CGPoint(x: 0.25, y: 0.75))
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

  func testMovieFileRecorderPreparationRequiresAConnection() async {
    let output: any VideoOutput = MovieFileVideoOutput()
    do {
      _ = try await output.makeRecorder()
      XCTFail("Preparing a movie-file recorder requires a Camera connection")
    } catch {
      XCTAssertTrue(error is RecordingError)
    }
  }

  func testConcreteVideoOutputPreservesRecorderType() {
    let movie = MovieFileVideoOutput()
    let frame = VideoFrameOutput()
    let _: (RecorderSettings) async throws -> VideoRecorder = movie.makeRecorder(settings:)
    let _: (RecorderSettings) async throws -> FrameRecorder = frame.makeRecorder(settings:)
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
