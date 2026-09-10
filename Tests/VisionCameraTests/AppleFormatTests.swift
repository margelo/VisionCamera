// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation
import CoreVideo
import XCTest

@testable import VisionCamera

final class AppleFormatTests: XCTestCase {
  func testPixelFormatsPreserveNativeIdentifiers() {
    let nativeFormats: [OSType] = [
      kCVPixelFormatType_32BGRA,
      kCVPixelFormatType_32RGBA,
      kCVPixelFormatType_24RGB,
      kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
      kCVPixelFormatType_422YpCbCr10BiPlanarVideoRange,
      kCVPixelFormatType_96VersatileBayerPacked12,
      kCVPixelFormatType_16VersatileBayer,
      kCVPixelFormatType_Lossless_420YpCbCr8BiPlanarVideoRange,
      kCVPixelFormatType_Lossy_420YpCbCr10PackedBiPlanarVideoRange,
      0x6675_7472,
    ]
    for native in nativeFormats {
      XCTAssertEqual(PixelFormat(osType: native).rawValue, native)
      XCTAssertEqual(PixelFormat(mediaSubType: .init(rawValue: native)).rawValue, native)
    }
    XCTAssertNotEqual(PixelFormat(rawValue: 0x6675_7472), .unknown)
    XCTAssertNotEqual(
      PixelFormat(rawValue: kCVPixelFormatType_Lossless_420YpCbCr8BiPlanarVideoRange),
      .yuv4208BitVideo)
  }

  func testNamedPixelFormatsMatchCoreVideoLayouts() {
    XCTAssertEqual(PixelFormat.rgbRgba8Bit.rawValue, kCVPixelFormatType_32RGBA)
    XCTAssertEqual(PixelFormat.rgbRgb8Bit.rawValue, kCVPixelFormatType_24RGB)
    XCTAssertEqual(PixelFormat.rawBayerPacked9612Bit.rawValue, kCVPixelFormatType_96VersatileBayerPacked12)
    XCTAssertEqual(PixelFormat.rawBayerUnpacked16Bit.rawValue, kCVPixelFormatType_16VersatileBayer)
    XCTAssertEqual(PixelFormat.depth16Bit.rawValue, kCVPixelFormatType_DepthFloat16)
    XCTAssertEqual(PixelFormat.disparity32Bit.rawValue, kCVPixelFormatType_DisparityFloat32)
  }

  func testPixelFormatConstraintDistinguishesUnknownNativeLayouts() {
    let format = PixelFormat(rawValue: 0x6675_7472)
    let constraint = PixelFormatConstraint(pixelFormat: format)
    XCTAssertEqual(constraint.resolve(mediaSubType: .init(rawValue: format.rawValue)).penalty.distance, 0)
    XCTAssertEqual(constraint.resolve(mediaSubType: .init(rawValue: 0x6675_7473)).penalty.distance, 1)
  }

  func testOutputPixelFormatRejectsUnsupportedLayoutBeforeNativeAssignment() throws {
    let nativeFormat = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
    let target = TargetVideoPixelFormat.pixelFormat(.yuv4208BitFull)
    let settings = try target.videoSettings(availablePixelFormats: [nativeFormat])
    XCTAssertEqual(settings[kCVPixelBufferPixelFormatTypeKey as String] as? OSType, nativeFormat)
    XCTAssertThrowsError(try target.videoSettings(availablePixelFormats: [kCVPixelFormatType_32BGRA]))
    XCTAssertTrue(try TargetVideoPixelFormat.native.videoSettings(availablePixelFormats: []).isEmpty)
  }

  func testDepthFormatsRoundTripAndRejectUnavailableConversion() throws {
    for format in DepthPixelFormat.allCases where format != .unknown {
      let native = try format.toCVPixelFormatType()
      XCTAssertEqual(DepthPixelFormat(osType: native), format)
      XCTAssertEqual(try format.validatedNativeFormat(availableDepthDataTypes: [native]), native)
      XCTAssertThrowsError(try format.validatedNativeFormat(availableDepthDataTypes: []))
    }
    XCTAssertThrowsError(try DepthPixelFormat.unknown.toCVPixelFormatType())
    XCTAssertEqual(DepthPixelFormat(osType: 0x6675_7472), .unknown)
  }

  func testAppleDeviceTypesIncludeExternalVirtualAndDepthCameras() {
    XCTAssertEqual(DeviceType(type: .builtInWideAngleCamera), .wideAngle)
    XCTAssertEqual(DeviceType(type: .builtInTripleCamera), .triple)
    XCTAssertEqual(DeviceType(type: .builtInTrueDepthCamera), .trueDepth)
    if #available(iOS 15.4, *) {
      XCTAssertEqual(DeviceType(type: .builtInLiDARDepthCamera), .lidarDepth)
    }
    if #available(iOS 17.0, *) {
      XCTAssertEqual(DeviceType(type: .external), .external)
      XCTAssertEqual(DeviceType(type: .continuityCamera), .continuity)
    }
    XCTAssertEqual(DeviceType(type: .init(rawValue: "FutureAppleCamera")), .unknown)
  }

  func testDynamicRangePreservesUnclassifiedNativeComponents() throws {
    let target = TargetDynamicRange(bitDepth: .bit10, colorSpace: .hlgBt2020, colorRange: .full)
    let selected = try target.resolve(mediaSubType: .init(rawValue: 0x6675_7472), supportedColorSpaces: [.sRGB])
    XCTAssertEqual(selected.resolvedValue, DynamicRange(bitDepth: .unknown, colorSpace: .srgb, colorRange: .unknown))
    XCTAssertGreaterThan(selected.penalty.distance, 0)
  }

  func testDynamicRangeReportsActualPrecisionAndRangeAfterFallback() throws {
    let target = TargetDynamicRange(bitDepth: .bit10, colorSpace: .hlgBt2020, colorRange: .full)
    let selected = try target.resolve(mediaSubType: .yuv4208BitVideo, supportedColorSpaces: [.sRGB, .P3_D65])
    XCTAssertEqual(selected.resolvedValue, DynamicRange(bitDepth: .bit8, colorSpace: .p3D65, colorRange: .video))
    XCTAssertEqual(CMFormatDescription.MediaSubType.rgbRgba8Bit.bitDepth, .bit8)
    XCTAssertEqual(CMFormatDescription.MediaSubType.yuv4448BitFull.colorRange, .full)
  }

  func testColorSpaceFallbackNeverReportsAnUnsupportedTarget() throws {
    let selected = try TargetColorSpace.appleLog2.resolve(supportedColorSpaces: [.HLG_BT2020])
    XCTAssertEqual(selected.resolvedValue, .hlgBt2020)
    XCTAssertThrowsError(try TargetColorSpace.srgb.resolve(supportedColorSpaces: []))
    let future = try XCTUnwrap(AVCaptureColorSpace(rawValue: 999))
    XCTAssertEqual(ColorSpace(colorSpace: future), .unknown)
    XCTAssertThrowsError(try TargetColorSpace.srgb.resolve(supportedColorSpaces: [future]))
    XCTAssertNil(ColorSpace.unknown.toAVCaptureColorSpace())
  }

  func testStabilizationFallbackTerminatesWhenNoModeIsSupported() {
    for mode in TargetStabilizationMode.allCases {
      let selected = mode.resolve(isSupported: { _ in false })
      XCTAssertEqual(selected.resolvedValue, .off)
    }
  }

  func testStabilizationFallbackReportsTheSelectedNativeMode() {
    let selected = TargetStabilizationMode.cinematicExtendedEnhanced.resolve(isSupported: { $0 == .cinematic })
    XCTAssertEqual(selected.resolvedValue, .cinematic)
    XCTAssertGreaterThan(selected.penalty.distance, 0)
  }

  func testFrameRatesKeepFractionalPrecisionAndClampToAvailableRanges() throws {
    let target = FPSConstraint(fps: 29.97)
    XCTAssertEqual(try target.resolve(frameRateRanges: [24...30]).resolvedValue, 29.97)
    XCTAssertEqual(try FPSConstraint(fps: 60).resolve(frameRateRanges: [24...30]).resolvedValue, 30)
    let minimum = CMTime(value: 1, timescale: 60)
    let maximum = CMTime(value: 1, timescale: 24)
    let duration = try target.frameDuration(minimum: minimum, maximum: maximum)
    XCTAssertEqual(1 / duration.seconds, 29.97, accuracy: 0.000_001)
    let exactBoundary = CMTime(value: 1001, timescale: 30_000)
    XCTAssertEqual(try target.frameDuration(minimum: exactBoundary, maximum: exactBoundary), exactBoundary)
  }

  func testFrameRateNegotiationRejectsInvalidRequestsAndEmptyCapabilities() {
    for fps in [0, -1, Double.nan, Double.infinity] {
      XCTAssertThrowsError(try FPSConstraint(fps: fps).resolve(frameRateRanges: [24...60]))
    }
    XCTAssertThrowsError(try FPSConstraint(fps: 30).resolve(frameRateRanges: []))
  }
}
