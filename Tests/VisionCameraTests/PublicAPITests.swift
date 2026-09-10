import AVFoundation
import UIKit
import VisionCamera
import XCTest

final class PublicAPITests: XCTestCase {
  func testStaticCameraQueriesDoNotRequireAFactoryInstance() {
    XCTAssertEqual(VisionCamera.cameraPermissionStatus, AVCaptureDevice.authorizationStatus(for: .video))
    XCTAssertEqual(VisionCamera.microphonePermissionStatus, AVCaptureDevice.authorizationStatus(for: .audio))
    XCTAssertEqual(VisionCamera.supportsMultiCamSessions, AVCaptureMultiCamSession.isMultiCamSupported)
    XCTAssertNil(VisionCamera.getCameraForId(id: "VisionCameraTests.missing-camera.\(UUID())"))

    let subscription = VisionCamera.addOnCameraDevicesChangedListener { _ in }
    subscription.remove()
  }

  func testDefaultSessionConstructionIsInfallibleAndDoesNotStartCapture() {
    let session = CameraSession()
    XCTAssertFalse(session.isRunning)
    XCTAssertFalse(session.session is AVCaptureMultiCamSession)
    XCTAssertTrue(session.session.inputs.isEmpty)
    XCTAssertTrue(session.session.outputs.isEmpty)
  }

  func testExplicitSingleCameraSessionDoesNotRequireMultiCameraSupport() throws {
    let session = try CameraSession(enableMultiCam: false)
    XCTAssertFalse(session.session is AVCaptureMultiCamSession)
    XCTAssertFalse(session.isRunning)
  }

  func testMultiCameraInitializerValidatesPlatformSupport() throws {
    if VisionCamera.supportsMultiCamSessions {
      let session = try CameraSession(enableMultiCam: true)
      XCTAssertTrue(session.session is AVCaptureMultiCamSession)
      XCTAssertFalse(session.isRunning)
    } else {
      XCTAssertThrowsError(try CameraSession(enableMultiCam: true)) { error in
        XCTAssertTrue(error is CameraError)
      }
    }
  }

  @MainActor
  func testDirectOutputInitializersApplyDefaultsAndSelectTheRecordingBackend() {
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

    let previewView = PreviewView(previewOutput: preview)
    XCTAssertTrue(previewView.previewOutput === preview)
  }

  func testNormalizedMeteringPointPreservesCaptureDeviceCoordinates() {
    let point = MeteringPoint(normalizedX: 0.25, normalizedY: 0.75)
    XCTAssertEqual(point.normalizedX, 0.25)
    XCTAssertEqual(point.normalizedY, 0.75)
    XCTAssertEqual(point.toNormalizedPoint(), CGPoint(x: 0.25, y: 0.75))
  }

  @MainActor
  func testPreviewMeteringRequiresAnAttachedOutput() {
    let preview = PreviewView()
    XCTAssertThrowsError(try preview.meteringPoint(at: CGPoint(x: 100, y: 50))) { error in
      XCTAssertTrue(error is CameraError)
    }
  }

  func testOutputSynchronizerRejectsEmptyAndDisconnectedOutputs() {
    XCTAssertThrowsError(try OutputSynchronizer(outputs: [])) { error in
      XCTAssertTrue(error is CameraError)
    }
    XCTAssertThrowsError(try OutputSynchronizer(outputs: [FrameOutput(), DepthOutput()])) { error in
      XCTAssertTrue(error is CameraError)
    }
  }

  func testFrameVideoRecorderPreparationRequiresAConnection() async {
    let output: any VideoOutput = VideoFrameOutput()
    do {
      _ = try await output.makeRecorder()
      XCTFail("Preparing a frame-based recorder requires a Camera connection")
    } catch {
      XCTAssertTrue(error is CameraError)
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
      XCTAssertTrue(error is CameraError)
    }
  }
}
