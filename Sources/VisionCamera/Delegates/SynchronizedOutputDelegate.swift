// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation
import Foundation

final class SynchronizedOutputDelegate: NSObject, AVCaptureDataOutputSynchronizerDelegate {
  private let outputs: [ObjectIdentifier: any CameraOutput]
  var onFrames: (([SynchronizedDataFrame]) -> Void)?
  var onFrameDropped: ((MediaType, AVCaptureOutput.DataDroppedReason) -> Void)?

  init(outputs: [any CameraOutput]) {
    self.outputs = Dictionary(
      uniqueKeysWithValues: outputs.compactMap { output in
        guard let nativeOutput = output as? any NativeCameraOutput else { return nil }
        return (ObjectIdentifier(nativeOutput.output), output)
      })
    super.init()
  }

  func dataOutputSynchronizer(
    _ synchronizer: AVCaptureDataOutputSynchronizer,
    didOutput synchronizedDataCollection: AVCaptureSynchronizedDataCollection
  ) {
    guard onFrames != nil || onFrameDropped != nil else { return }

    var frames: [SynchronizedDataFrame] = []
    for output in synchronizer.dataOutputs {
      // A collection may omit outputs that have no sample ready for this timestamp.
      guard let data = synchronizedDataCollection.synchronizedData(for: output) else { continue }
      let type: MediaType
      switch output {
      case is AVCaptureAudioDataOutput: type = .other(.audio)
      case is AVCaptureDepthDataOutput: type = .depth
      case is AVCaptureMetadataOutput: type = .metadata
      default: type = .video
      }
      do {
        switch data {
        case let sample as AVCaptureSynchronizedSampleBufferData:
          guard !sample.sampleBufferWasDropped else {
            onFrameDropped?(type, sample.droppedReason)
            continue
          }
          if output is AVCaptureAudioDataOutput {
            let metadata = MediaSampleMetadata(timestamp: sample.timestamp, orientation: .up, isMirrored: false)
            frames.append(SynchronizedDataFrame(data: .audio(sample.sampleBuffer), metadata: metadata))
          } else {
            let metadata = try metadata(at: sample.timestamp, from: output, mediaType: .video)
            frames.append(SynchronizedDataFrame(data: .video(sample.sampleBuffer), metadata: metadata))
          }
        case let depth as AVCaptureSynchronizedDepthData:
          guard !depth.depthDataWasDropped else {
            onFrameDropped?(type, depth.droppedReason)
            continue
          }
          let metadata = try metadata(at: depth.timestamp, from: output, mediaType: .depthData)
          frames.append(SynchronizedDataFrame(data: .depth(depth.depthData), metadata: metadata))
        case let objects as AVCaptureSynchronizedMetadataObjectData:
          // Metadata coordinates stay in the native camera coordinate system. They have no pixel transform.
          let metadata = MediaSampleMetadata(timestamp: objects.timestamp, orientation: .up, isMirrored: false)
          frames.append(SynchronizedDataFrame(data: .metadata(objects.metadataObjects), metadata: metadata))
        default:
          logger.error("Received an unsupported synchronized data type: \(data).")
        }
      } catch {
        logger.error("Failed to read synchronized \(type.toAVMediaType().rawValue) data: \(error).")
        onFrameDropped?(type, .none)
      }
    }
    onFrames?(frames)
  }

  private func metadata(at timestamp: CMTime, from output: AVCaptureOutput, mediaType: AVMediaType) throws -> MediaSampleMetadata {
    guard let connection = output.connection(with: mediaType) else {
      throw CameraError(message: "The synchronized output has no \(mediaType.rawValue) connection.")
    }
    return metadata(
      at: timestamp, from: output,
      bufferOrientation: connection.orientation, isBufferMirrored: connection.isVideoMirrored)
  }

  func metadata(
    at timestamp: CMTime, from output: AVCaptureOutput,
    bufferOrientation: CameraOrientation, isBufferMirrored: Bool
  ) -> MediaSampleMetadata {
    switch outputs[ObjectIdentifier(output)] {
    case let frame as FrameOutput:
      return frame.getMediaSampleMetadata(at: timestamp, orientation: bufferOrientation, isMirrored: isBufferMirrored)
    case let depth as DepthOutput:
      return depth.getMediaSampleMetadata(at: timestamp, orientation: bufferOrientation, isMirrored: isBufferMirrored)
    default:
      return MediaSampleMetadata(timestamp: timestamp, orientation: bufferOrientation, isMirrored: isBufferMirrored)
    }
  }
}
