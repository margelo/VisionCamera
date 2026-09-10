// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation
import Foundation

/// Retains depth data and its capture metadata. Use an instance on one queue at a time.
public final class Depth {
  public private(set) var depthData: AVDepthData?
  public let metadata: MediaSampleMetadata
  private static let conversionQueue = DispatchQueue(label: "com.margelo.camera.depth-conversion", qos: .userInitiated)

  public init(depthData: AVDepthData, metadata: MediaSampleMetadata) {
    self.depthData = depthData
    self.metadata = metadata
  }

  public var pixelBuffer: CVPixelBuffer? { depthData?.depthDataMap }
  public var memorySize: Int { pixelBuffer?.memorySize ?? 0 }
  public var isValid: Bool { depthData != nil }
  public var width: Double { pixelBuffer.map { Double(CVPixelBufferGetWidth($0)) } ?? 0 }
  public var height: Double { pixelBuffer.map { Double(CVPixelBufferGetHeight($0)) } ?? 0 }
  public var bytesPerRow: Double { pixelBuffer.map { Double(CVPixelBufferGetBytesPerRow($0)) } ?? 0 }
  public var timestamp: Double { metadata.timestamp.seconds }
  public var orientation: CameraOrientation { metadata.orientation }
  public var isMirrored: Bool { metadata.isMirrored }
  public var isDepthDataFiltered: Bool { depthData?.isDepthDataFiltered ?? false }

  public var pixelFormat: DepthPixelFormat {
    guard let depthData else { return .unknown }
    return DepthPixelFormat(osType: depthData.depthDataType)
  }

  public var depthDataAccuracy: DepthDataAccuracy {
    guard let depthData else { return .unknown }
    return DepthDataAccuracy(av: depthData.depthDataAccuracy)
  }

  public var depthDataQuality: DepthDataQuality {
    guard let depthData else { return .unknown }
    return DepthDataQuality(av: depthData.depthDataQuality)
  }

  public var availableDepthPixelFormats: [DepthPixelFormat] {
    depthData?.availableDepthDataTypes.map { DepthPixelFormat(osType: $0) } ?? []
  }

  public var cameraCalibrationData: CameraCalibrationData? {
    depthData?.cameraCalibrationData.map { CameraCalibrationData(calibrationData: $0) }
  }

  /// Releases this instance's reference. Caller-retained native data remains valid.
  public func dispose() { depthData = nil }

  public func getDepthData() throws -> AVDepthData {
    guard let depthData else { throw CameraError(message: "This depth frame has been disposed.") }
    return depthData
  }

  public func getPixelBuffer() throws -> CVPixelBuffer { try getDepthData().depthDataMap }
  public func getNativeBuffer() throws -> CVPixelBuffer { try getPixelBuffer() }

  /// The pointer is valid only during `body`. Copy its bytes to retain them afterward.
  public func withUnsafeBytes<Result>(_ body: (UnsafeRawBufferPointer) throws -> Result) throws -> Result {
    let pixelBuffer = try getPixelBuffer()
    return try pixelBuffer.withReadOnlyBytes(body)
  }

  public func rotate(orientation: CameraOrientation, isMirrored: Bool) throws -> Depth {
    let depthData = try getDepthData()
    let rotated = depthData.applyingExifOrientation(orientation.toCGOrientation(isMirrored: isMirrored))
    return Depth(depthData: rotated, metadata: metadata)
  }

  public func rotateAsync(orientation: CameraOrientation, isMirrored: Bool) async throws -> Depth {
    let depthData = try getDepthData()
    let metadata = metadata
    return try await Self.conversionQueue.perform {
      let rotated = depthData.applyingExifOrientation(orientation.toCGOrientation(isMirrored: isMirrored))
      return Depth(depthData: rotated, metadata: metadata)
    }
  }

  public func convert(pixelFormat: DepthPixelFormat) throws -> Depth {
    let depthData = try getDepthData()
    let converted = depthData.converting(toDepthDataType: try pixelFormat.toCVPixelFormatType())
    return Depth(depthData: converted, metadata: metadata)
  }

  public func convertAsync(pixelFormat: DepthPixelFormat) async throws -> Depth {
    let depthData = try getDepthData()
    let metadata = metadata
    let osFormat = try pixelFormat.toCVPixelFormatType()
    return try await Self.conversionQueue.perform {
      Depth(depthData: depthData.converting(toDepthDataType: osFormat), metadata: metadata)
    }
  }

  public func convertCameraPointToDepthPoint(cameraPoint: Point) throws -> Point {
    let matrix = FrameCoordinateSystemConverter.getCameraToFrameMatrix(
      pixelBuffer: try getPixelBuffer(), orientation: orientation, isMirrored: isMirrored)
    return cameraPoint.applying(matrix)
  }

  public func convertDepthPointToCameraPoint(depthPoint: Point) throws -> Point {
    let matrix = FrameCoordinateSystemConverter.getFrameToCameraMatrix(
      pixelBuffer: try getPixelBuffer(), orientation: orientation, isMirrored: isMirrored)
    return depthPoint.applying(matrix)
  }

  public func toFrame() throws -> Frame {
    let pixelBuffer = try getPixelBuffer()
    let format = try CMFormatDescription(imageBuffer: pixelBuffer)
    let timing = CMSampleTimingInfo(
      duration: .zero, presentationTimeStamp: metadata.timestamp, decodeTimeStamp: .zero)
    let sampleBuffer = try CMSampleBuffer(
      imageBuffer: pixelBuffer, formatDescription: format, sampleTiming: timing)
    return Frame(buffer: sampleBuffer, metadata: metadata)
  }
}
