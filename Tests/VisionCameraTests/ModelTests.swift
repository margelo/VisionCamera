import CoreLocation
import CoreMedia
import UIKit
import VisionCamera
import XCTest

final class ModelTests: XCTestCase {
  func testPhotoDefaultsPreserveCaptureQuality() {
    let options = PhotoOutputOptions()
    XCTAssertEqual(options.targetResolution, CGSize(width: 3024, height: 4032))
    XCTAssertEqual(options.containerFormat, .native)
    XCTAssertEqual(options.quality, 0.9)
    XCTAssertEqual(options.qualityPrioritization, .balanced)
    XCTAssertNil(options.previewImageTargetSize)
  }

  func testFrameDefaultsPreserveBufferDeliveryPolicy() {
    let options = FrameOutputOptions()
    XCTAssertEqual(options.targetResolution, CGSize(width: 720, height: 1280))
    XCTAssertEqual(options.pixelFormat, .native)
    XCTAssertTrue(options.discardsLateFrames)
    XCTAssertTrue(options.allowsDeferredStart)
    XCTAssertFalse(options.isCameraIntrinsicMatrixDeliveryEnabled)
    XCTAssertFalse(options.rotatesBuffers)
    XCTAssertFalse(options.usesPreviewSizedBuffers)
  }

  func testDepthDefaultsPreserveFilteringAndDeliveryPolicy() {
    let options = DepthOutputOptions()
    XCTAssertEqual(options.targetResolution, CGSize(width: 480, height: 854))
    XCTAssertTrue(options.isFilteringEnabled)
    XCTAssertTrue(options.discardsLateFrames)
    XCTAssertTrue(options.allowsDeferredStart)
    XCTAssertFalse(options.rotatesBuffers)
  }

  func testVideoDefaultsDeferOptionalSettingsToTheRecorder() {
    let options = VideoOutputOptions()
    XCTAssertEqual(options.targetResolution, CGSize(width: 1080, height: 1920))
    XCTAssertFalse(options.isAudioEnabled)
    XCTAssertNil(options.bitRate)
    XCTAssertEqual(options.fileType, .mov)
    XCTAssertNil(VideoOutputSettings().codec)
  }

  func testPublicCaptureSettingsAcceptNativeValues() {
    let location = CLLocation(latitude: 48.2082, longitude: 16.3738)
    var photoSettings = CapturePhotoSettings(location: location)
    photoSettings.flashMode = .on
    XCTAssertEqual(photoSettings.flashMode, .on)
    XCTAssertEqual(photoSettings.location, location)

    let duration = CMTime(value: 12, timescale: 1)
    let recorderSettings = RecorderSettings(location: location, maxDuration: duration)
    XCTAssertEqual(recorderSettings.location, location)
    XCTAssertEqual(recorderSettings.maxDuration, duration)

    var deliveredImage: UIImage?
    let callbacks = CapturePhotoCallbacks(didReceivePreviewImage: { deliveredImage = $0 })
    let image = UIImage()
    callbacks.didReceivePreviewImage?(image)
    XCTAssertTrue(deliveredImage === image)
  }

  func testFocusResetDistinguishesDefaultDisabledAndTimedBehavior() {
    XCTAssertEqual(FocusOptions().reset, .after(5))
    XCTAssertEqual(FocusOptions(reset: .never).reset, .never)
    XCTAssertEqual(FocusOptions(reset: .after(2)).reset, .after(2))
  }
}
