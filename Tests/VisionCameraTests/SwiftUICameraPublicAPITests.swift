import SwiftUI
import VisionCamera
import XCTest

final class SwiftUICameraPublicAPITests: XCTestCase {
  @MainActor
  func testCameraComposesThroughPublicImportWithoutStartingCapture() {
    let photo = PhotoOutput()
    let movie = MovieFileVideoOutput()
    var zoom = 1.0
    let binding = Binding(get: { zoom }, set: { zoom = $0 })
    let camera: Camera = Camera(
      device: .position(.back), isActive: false, outputs: [photo, movie],
      constraints: [.fps(FPSConstraint(fps: 30))]
    )
    .zoom(binding)
    .exposureBias(0)
    .torchMode(.off)
    .resizeMode(.cover)
    .mirrorMode(.auto)
    .orientationSource(.device)
    .initialZoom(1)
    .initialExposureBias(0)
    .sessionConfiguration(CameraSessionConfiguration(allowHapticsAndSystemSoundsPlayback: true))
    .controllerConfiguration(CameraControllerConfiguration())
    .enableZoomGesture()
    .enableTapToFocusGesture()
    .onConfigured { _ in XCTFail("Constructing a View must not configure capture") }
    .onSessionConfigSelected { _ in XCTFail("Constructing a View must not negotiate capture") }
    .onStarted { XCTFail("Constructing a View must not start capture") }
    .onStopped {}
    .onError { _ in XCTFail("Constructing a View must not perform camera operations") }
    .onInterruptionStarted { _ in }
    .onInterruptionEnded {}
    .onSubjectAreaChanged {}
    .onPreviewStarted {}
    .onPreviewStopped {}
    .onPreviewChanged { _ in }
    .onUIRotationChanged { _ in }
    _ = camera.body
    _ = camera.zoom(2).enableZoomGesture(false).orientationSource(nil).padding().accessibilityIdentifier("camera")
    XCTAssertEqual(zoom, 1)
    XCTAssertNil(photo.output.connection(with: .video))
    XCTAssertNil(movie.output.connection(with: .video))
  }
}
