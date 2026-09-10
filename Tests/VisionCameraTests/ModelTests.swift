import CoreLocation
import UIKit
import VisionCamera
import XCTest

final class ModelTests: XCTestCase {
  func testPhotoDefaultsPreserveCaptureQuality() {
    let options = PhotoOutputOptions()
    XCTAssertEqual(options.targetResolution, Size(width: 3024, height: 4032))
    XCTAssertEqual(options.containerFormat, .native)
    XCTAssertEqual(options.quality, 0.9)
    XCTAssertEqual(options.qualityPrioritization, .balanced)
    XCTAssertNil(options.previewImageTargetSize)
  }

  func testFrameDefaultsPreserveBufferDeliveryPolicy() {
    let options = FrameOutputOptions()
    XCTAssertEqual(options.targetResolution, Size(width: 720, height: 1280))
    XCTAssertEqual(options.pixelFormat, .native)
    XCTAssertTrue(options.dropFramesWhileBusy)
    XCTAssertTrue(options.allowDeferredStart)
    XCTAssertFalse(options.enableCameraMatrixDelivery)
    XCTAssertFalse(options.enablePhysicalBufferRotation)
    XCTAssertFalse(options.enablePreviewSizedOutputBuffers)
  }

  func testDepthDefaultsPreserveFilteringAndDeliveryPolicy() {
    let options = DepthFrameOutputOptions()
    XCTAssertEqual(options.targetResolution, Size(width: 480, height: 854))
    XCTAssertTrue(options.enableFiltering)
    XCTAssertTrue(options.dropFramesWhileBusy)
    XCTAssertTrue(options.allowDeferredStart)
    XCTAssertFalse(options.enablePhysicalBufferRotation)
  }

  func testVideoDefaultsDeferOptionalSettingsToTheRecorder() {
    let options = VideoOutputOptions()
    XCTAssertEqual(options.targetResolution, Size(width: 1080, height: 1920))
    XCTAssertNil(options.enableAudio)
    XCTAssertNil(options.enablePersistentRecorder)
    XCTAssertNil(options.enableHigherResolutionCodecs)
    XCTAssertNil(options.targetBitRate)
    XCTAssertNil(options.fileType)
    XCTAssertNil(VideoOutputSettings().codec)
  }

  func testPublicCaptureSettingsAcceptNativeValues() {
    let location = CLLocation(latitude: 48.2082, longitude: 16.3738)
    var photoSettings = CapturePhotoSettings(location: location)
    photoSettings.flashMode = .on
    XCTAssertEqual(photoSettings.flashMode, .on)
    XCTAssertEqual(photoSettings.location, location)

    let recorderSettings = RecorderSettings(location: location, maxDuration: 12)
    XCTAssertEqual(recorderSettings.location, location)
    XCTAssertEqual(recorderSettings.maxDuration, 12)

    var deliveredImage: UIImage?
    let callbacks = CapturePhotoCallbacks(onPreviewImageAvailable: { deliveredImage = $0 })
    let image = UIImage()
    callbacks.onPreviewImageAvailable?(image)
    XCTAssertTrue(deliveredImage === image)
  }

  func testFocusResetDistinguishesDefaultDisabledAndTimedBehavior() {
    XCTAssertNil(FocusOptions().autoResetAfter)
    XCTAssertEqual(FocusOptions(autoResetAfter: .never).autoResetAfter, .never)
    XCTAssertEqual(FocusOptions(autoResetAfter: .after(2)).autoResetAfter, .after(2))
  }
}
