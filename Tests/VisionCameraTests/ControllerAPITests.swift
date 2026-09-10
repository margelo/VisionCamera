import AVFoundation
import XCTest

@testable import VisionCamera

final class ControllerAPITests: XCTestCase {
  func testTorchLevelsUseTheNativeOpenLowerBound() throws {
    for level: Float in [Float.leastNonzeroMagnitude, 0.0001, 0.5, 1, AVCaptureDevice.maxAvailableTorchLevel] {
      XCTAssertNoThrow(try CameraController.validateTorchLevel(level))
    }
    for level: Float in [-1, 0, 1.0001, .nan, .infinity, -.infinity] {
      XCTAssertThrowsError(try CameraController.validateTorchLevel(level))
    }
  }

  func testMeteringCoordinatesRejectValuesOutsideTheCaptureDeviceSpace() throws {
    for coordinate in [0.0, 0.5, 1.0] {
      XCTAssertNoThrow(try MeteringPoint(normalizedX: coordinate, normalizedY: coordinate).validate())
    }
    for coordinate in [-0.1, 1.1, .nan, .infinity, -.infinity] {
      XCTAssertThrowsError(try MeteringPoint(normalizedX: coordinate, normalizedY: 0.5).validate())
      XCTAssertThrowsError(try MeteringPoint(normalizedX: 0.5, normalizedY: coordinate).validate())
    }
  }

  func testFocusOptionsHaveConcreteDefaultsAndValidateResetDelays() throws {
    let options = FocusOptions()
    XCTAssertEqual(options.responsiveness, .snappy)
    XCTAssertEqual(options.adaptiveness, .continuous)
    XCTAssertEqual(options.autoResetAfter, .after(5))
    XCTAssertNil(options.modes)
    XCTAssertNoThrow(try FocusReset.never.validate())
    XCTAssertNoThrow(try FocusReset.after(0).validate())
    XCTAssertNoThrow(try FocusReset.after(2).validate())
    for delay in [-1.0, .nan, .infinity, -.infinity] {
      XCTAssertThrowsError(try FocusReset.after(delay).validate())
    }
  }

  func testZoomRampsValidateTheNativeRangeAndFinitePositiveRate() throws {
    XCTAssertNoThrow(try CameraController.validateZoom(2, rate: 3, range: 1...5))
    for zoom in [0.0, 6.0, .nan, .infinity] {
      XCTAssertThrowsError(try CameraController.validateZoom(zoom, rate: 3, range: 1...5))
    }
    for rate in [0.0, -1.0, .nan, .infinity, Double.greatestFiniteMagnitude] {
      XCTAssertThrowsError(try CameraController.validateZoom(2, rate: rate, range: 1...5))
    }
  }

  func testControllerReportsNativeModeTypesWithoutACompatibilityConverter() {
    let _: KeyPath<CameraController, AVCaptureDevice.FocusMode> = \.focusMode
    let _: KeyPath<CameraController, AVCaptureDevice.ExposureMode> = \.exposureMode
    let _: KeyPath<CameraController, AVCaptureDevice.WhiteBalanceMode> = \.whiteBalanceMode
    let _: KeyPath<CameraController, AVCaptureDevice.TorchMode> = \.torchMode
    let _: KeyPath<CameraController, AVCaptureDevice.WhiteBalanceGains> = \.whiteBalanceGains
    XCTAssertEqual(VisionCamera.cameraPermissionStatus, AVCaptureDevice.authorizationStatus(for: .video))
    XCTAssertEqual(VisionCamera.microphonePermissionStatus, AVCaptureDevice.authorizationStatus(for: .audio))
  }

  func testMetadataCoordinatesCannotRequestMirroring() {
    let output = ObjectOutput(options: ObjectOutputOptions(enabledObjectTypes: [.qr]))
    XCTAssertEqual(output.outputOrientation, .up)
    XCTAssertThrowsError(try output.configure(config: OutputConfiguration(mirrorMode: .on)))
  }

  func testAudioMixingConfigurationPreservesExplicitAndUnspecifiedValues() {
    let unchanged = CameraSessionConfiguration()
    XCTAssertNil(unchanged.allowHapticsAndSystemSoundsPlayback)
    if #available(iOS 18.0, *) {
      XCTAssertNil(unchanged.allowBackgroundAudioPlayback)
      var mixing = CameraSessionConfiguration(allowBackgroundAudioPlayback: true)
      XCTAssertEqual(mixing.allowBackgroundAudioPlayback, true)
      mixing.allowBackgroundAudioPlayback = false
      XCTAssertEqual(mixing.allowBackgroundAudioPlayback, false)
      mixing.allowBackgroundAudioPlayback = nil
      XCTAssertEqual(mixing, unchanged)
    }
  }
}
