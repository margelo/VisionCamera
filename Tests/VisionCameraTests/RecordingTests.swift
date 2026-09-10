import AVFoundation
import CoreLocation
import XCTest

@testable import VisionCamera

final class RecordingTests: XCTestCase {
  func testInvalidRecordingSettingsKeepTheirAssociatedValues() throws {
    let remoteURL = try XCTUnwrap(URL(string: "https://example.com/video.mov"))
    XCTAssertThrowsError(try RecorderSettings(fileURL: remoteURL).validate()) { error in
      guard case .invalidDestination(let received)? = error as? RecordingError else {
        return XCTFail("Expected an invalid-destination error")
      }
      XCTAssertEqual(received, remoteURL)
    }
    for duration in [CMTime.zero, .negativeInfinity, .positiveInfinity, .invalid, CMTime(value: -1, timescale: 1)] {
      XCTAssertThrowsError(try RecorderSettings(maxDuration: duration).validate()) { error in
        guard case .invalidDurationLimit(let received)? = error as? RecordingError else {
          return XCTFail("Expected a duration-limit error")
        }
        XCTAssertEqual(received, duration)
      }
    }
    for byteCount: Int64 in [0, -1] {
      XCTAssertThrowsError(try RecorderSettings(maxFileSize: byteCount).validate()) { error in
        guard case .invalidFileSizeLimit(let received)? = error as? RecordingError else {
          return XCTFail("Expected a file-size-limit error")
        }
        XCTAssertEqual(received, byteCount)
      }
    }
    XCTAssertNoThrow(try RecorderSettings(maxDuration: CMTime(value: 1, timescale: 30), maxFileSize: 1).validate())
  }

  func testUnusedMovieRecordersHaveIndependentIdleStatus() async throws {
    let output = AVCaptureMovieFileOutput()
    let queue = DispatchQueue(label: "VisionCameraTests.shared-movie-output")
    let coordinator = MovieFileRecordingCoordinator()
    let first = try VideoRecorder(videoOutput: output, queue: queue, coordinator: coordinator, fileType: .mov, settings: .init())
    let second = try VideoRecorder(videoOutput: output, queue: queue, coordinator: coordinator, fileType: .mov, settings: .init())
    XCTAssertNotEqual(first.fileURL, second.fileURL)
    for recorder in [first, second] {
      let status = await recorder.status()
      XCTAssertEqual(status, RecordingStatus(isRecording: false, isPaused: false, duration: .invalid, fileSize: 0))
      await recorder.stop()
      do {
        try await recorder.cancel()
        XCTFail("An unused recorder must not cancel another recording")
      } catch RecordingError.notRecording {
      }
      do {
        try await recorder.pause()
        XCTFail("An unused recorder must not pause another recording")
      } catch RecordingError.notRecording {
      }
      do {
        try await recorder.resume()
        XCTFail("An unused recorder must not resume another recording")
      } catch RecordingError.notRecording {
      }
    }
  }

  func testMovieOutputRemainsReservedUntilItsRecordingReleasesIt() throws {
    let coordinator = MovieFileRecordingCoordinator()
    let first = UUID()
    let second = UUID()
    try coordinator.reserve(for: first)
    XCTAssertThrowsError(try coordinator.reserve(for: second)) { error in
      guard case .recordingInProgress? = error as? RecordingError else {
        return XCTFail("The output must remain reserved until finalization finishes")
      }
    }
    coordinator.release(for: second)
    XCTAssertThrowsError(try coordinator.reserve(for: second))
    coordinator.release(for: first)
    XCTAssertNoThrow(try coordinator.reserve(for: second))
  }

  func testFrameRecorderStatusReadsOwnedFileBytesAndKeepsSnapshotsImmutable() async throws {
    let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    let url = directory.appendingPathComponent("recording.mov")
    let recorder = try FrameRecorder(
      orientation: .up, masterClock: CMClockGetHostTimeClock(), fileType: .mov,
      settings: RecorderSettings(fileURL: url), delegate: StubRecorderDelegate())
    let before = try await recorder.status()
    XCTAssertEqual(before, RecordingStatus(isRecording: false, isPaused: false, duration: .zero, fileSize: 0))
    try Data(repeating: 0x42, count: 73).write(to: url)
    let after = try await recorder.status()
    XCTAssertEqual(after.fileSize, 73)
    XCTAssertFalse(after.isRecording)
    XCTAssertEqual(before.fileSize, 0)
  }

  func testMovieLocationMetadataChangesPreserveOtherTags() {
    let output = AVCaptureMovieFileOutput()
    let software = AVMutableMetadataItem()
    software.identifier = .quickTimeMetadataSoftware
    software.value = "VisionCameraTests" as NSString
    let previous = AVMutableMetadataItem()
    previous.identifier = .quickTimeMetadataLocationISO6709
    previous.value = "+48.0+016.0/" as NSString
    output.metadata = [software, previous]
    let current = AVMutableMetadataItem()
    current.identifier = .quickTimeMetadataLocationISO6709
    current.value = "+37.0-122.0/" as NSString
    output.applyLocationMetadata(current)
    XCTAssertEqual(output.metadata?.count, 2)
    XCTAssertEqual(output.metadata?.first { $0.identifier == .quickTimeMetadataLocationISO6709 }?.stringValue, current.stringValue)
    XCTAssertEqual(output.metadata?.first { $0.identifier == .quickTimeMetadataSoftware }?.stringValue, software.stringValue)
    output.applyLocationMetadata(nil)
    XCTAssertEqual(output.metadata?.count, 1)
    XCTAssertEqual(output.metadata?.first?.identifier, .quickTimeMetadataSoftware)
  }

  func testPreparingAnotherMovieRecorderDoesNotChangeOutputLocationMetadata() async throws {
    let output = MovieFileVideoOutput()
    let existing = AVMutableMetadataItem()
    existing.identifier = .quickTimeMetadataLocationISO6709
    existing.value = "+48.0+016.0/" as NSString
    output.output.metadata = [existing]
    let recorder = try await output.makeRecorder(settings: RecorderSettings(location: CLLocation(latitude: 37, longitude: -122)))
    XCTAssertEqual(output.output.metadata?.first?.stringValue, existing.stringValue)
    let status = await recorder.status()
    XCTAssertFalse(status.isRecording)
  }

  private final class StubRecorderDelegate: RecorderDelegate {
    func onRecorderWillStart() {}
    func onRecorderDidStop() {}
  }
}
