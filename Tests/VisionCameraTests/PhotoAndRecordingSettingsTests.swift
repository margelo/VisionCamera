import AVFoundation
import UniformTypeIdentifiers
import XCTest

@testable import VisionCamera

final class PhotoAndRecordingSettingsTests: XCTestCase {
  func testAutomaticPhotoFormatUsesOnlyAdvertisedCodecs() throws {
    let preferred = try TargetPhotoContainerFormat.automatic().processedFormat(availableCodecs: [.jpeg, .hevc])
    XCTAssertEqual(preferred[AVVideoCodecKey] as? AVVideoCodecType, .hevc)
    let fallback = try TargetPhotoContainerFormat.automatic().processedFormat(availableCodecs: [.jpeg])
    XCTAssertEqual(fallback[AVVideoCodecKey] as? AVVideoCodecType, .jpeg)
    XCTAssertThrowsError(try TargetPhotoContainerFormat.automatic().processedFormat(availableCodecs: []))
    XCTAssertThrowsError(try TargetPhotoContainerFormat.heic().processedFormat(availableCodecs: [.jpeg]))
  }

  func testProcessedPhotoCompressionIsValidatedAndPreserved() throws {
    let format = try TargetPhotoContainerFormat.jpeg(quality: 0.7).processedFormat(availableCodecs: [.jpeg])
    let compression = try XCTUnwrap(format[AVVideoCompressionPropertiesKey] as? [String: Double])
    XCTAssertEqual(compression[AVVideoQualityKey], 0.7)
    for invalid in [Double.nan, .infinity, -0.1, 1.1] {
      XCTAssertThrowsError(try TargetPhotoContainerFormat.jpeg(quality: invalid).processedFormat(availableCodecs: [.jpeg]))
    }
    XCTAssertThrowsError(try TargetPhotoContainerFormat.dng.processedFormat(availableCodecs: [.jpeg]))
  }

  func testPhotoContainerMatchesActualNativeSettings() throws {
    let jpeg = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.jpeg])
    let heic = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
    XCTAssertEqual(PhotoContainerFormat(settings: jpeg), .jpeg)
    XCTAssertEqual(PhotoContainerFormat(settings: heic), .heic)
    XCTAssertEqual(PhotoContainerFormat(avFileType: .tif), .tiff)
    XCTAssertEqual(PhotoContainerFormat(avFileType: .dng), .dng)
    XCTAssertEqual(try PhotoContainerFormat.dng.uniformType.preferredFilenameExtension, "dng")
    if #available(iOS 26.0, *) {
      XCTAssertEqual(PhotoContainerFormat(avFileType: .dcm), .dcm)
    }
  }

  func testBayerRAWUsesItsRequiredSpeedPrioritization() throws {
    let raw = AVCapturePhotoSettings(rawPixelFormatType: kCVPixelFormatType_14Bayer_RGGB)
    try raw.applyQualityPrioritization(nil)
    XCTAssertEqual(raw.photoQualityPrioritization, .speed)
    try raw.applyQualityPrioritization(.speed)
    XCTAssertThrowsError(try raw.applyQualityPrioritization(.balanced))
    XCTAssertThrowsError(try raw.applyQualityPrioritization(.quality))

    let processed = AVCapturePhotoSettings()
    try processed.applyQualityPrioritization(nil)
    XCTAssertEqual(processed.photoQualityPrioritization, .balanced)
    try processed.applyQualityPrioritization(.quality)
    XCTAssertEqual(processed.photoQualityPrioritization, .quality)
  }

  func testUnknownPhotoContainerCannotBeMislabeledForExport() {
    let format = PhotoContainerFormat(avFileType: AVFileType(rawValue: "future.photo-container"))
    XCTAssertEqual(format, .unknown)
    XCTAssertThrowsError(try format.uniformType)
  }

  func testRecorderLimitsRejectInvalidValuesWithoutNumericTraps() throws {
    try RecorderSettings(maxDuration: CMTime(seconds: 1.5, preferredTimescale: 600), maxFileSize: Int64.max).validate()
    for invalid in [CMTime.invalid, .positiveInfinity, .negativeInfinity, .zero, CMTime(value: -1, timescale: 600)] {
      XCTAssertThrowsError(try RecorderSettings(maxDuration: invalid).validate())
    }
    XCTAssertThrowsError(try RecorderSettings(maxFileSize: 0).validate())
    XCTAssertThrowsError(try RecorderSettings(maxFileSize: -1).validate())
    XCTAssertThrowsError(try RecorderSettings(fileURL: URL(string: "https://example.com/movie.mov")!).validate())
    try RecorderSettings(fileURL: URL(fileURLWithPath: "/tmp/movie.mov")).validate()
  }

  func testProResBitRatePolicyIncludesAllNativeVariants() throws {
    let options = VideoOutputOptions(bitRate: 10_000_000)
    try options.validateBitRate(for: .h264)
    try options.validateBitRate(for: .hevc)
    let codecs: [AVVideoCodecType] = [.proRes422Proxy, .proRes422LT, .proRes422, .proRes422HQ, .proRes4444]
    for codec in codecs {
      XCTAssertThrowsError(try options.validateBitRate(for: codec))
      try VideoOutputOptions().validateBitRate(for: codec)
    }
    if #available(iOS 18.0, *) {
      XCTAssertThrowsError(try options.validateBitRate(for: .appleProRes4444XQ))
    }
    if #available(iOS 26.0, *) {
      XCTAssertThrowsError(try options.validateBitRate(for: .proResRAW))
      XCTAssertThrowsError(try options.validateBitRate(for: .proResRAWHQ))
    }
    XCTAssertThrowsError(try VideoOutputOptions(bitRate: 0).validateBitRate(for: .h264))
    XCTAssertThrowsError(try VideoOutputOptions(bitRate: -1).validateBitRate(for: .hevc))
  }

  func testVideoCodecSelectionRequiresConnectedOutput() async {
    let outputs: [any VideoOutput] = [MovieFileVideoOutput(), VideoFrameOutput(fileType: .mp4)]
    for output in outputs {
      do {
        try await output.setVideoCodec(.h264)
        XCTFail("Selecting a codec before connecting the output must fail.")
      } catch {
        XCTAssertTrue(error.localizedDescription.contains("not connected"))
      }
    }
  }
}
