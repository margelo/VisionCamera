// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation
import Foundation
import UIKit

public final class Photo {
  public let photo: AVCapturePhoto
  public let metadata: MediaSampleMetadata
  public let containerFormat: PhotoContainerFormat
  private static let processingQueue = DispatchQueue(label: "com.margelo.camera.photo-processing", qos: .userInitiated)
  private static let fileQueue = DispatchQueue(label: "com.margelo.camera.photo-files", qos: .utility)

  public init(photo: AVCapturePhoto, metadata: MediaSampleMetadata, containerFormat: PhotoContainerFormat) {
    self.photo = photo
    self.metadata = metadata
    self.containerFormat = containerFormat
  }

  public var memorySize: Int { photo.memorySize }
  public var timestamp: Double { photo.timestamp.seconds }
  public var isMirrored: Bool { metadata.isMirrored }
  public var orientation: CameraOrientation { metadata.orientation }
  public var isRawPhoto: Bool { photo.isRawPhoto }
  public var pixelBuffer: CVPixelBuffer? { photo.pixelBuffer }
  public var hasPixelBuffer: Bool { pixelBuffer != nil }
  public var width: Double { Double(size.width) }
  public var height: Double { Double(size.height) }

  public var depth: Depth? {
    photo.depthData.map { Depth(depthData: $0, metadata: metadata) }
  }

  public var size: CMVideoDimensions {
    isRawPhoto ? photo.resolvedSettings.rawPhotoDimensions : photo.resolvedSettings.photoDimensions
  }

  public var calibrationData: CameraCalibrationData? {
    photo.cameraCalibrationData.map { CameraCalibrationData(calibrationData: $0) }
  }

  public func getPixelBuffer() throws -> CVPixelBuffer {
    guard let pixelBuffer else { throw CameraError(message: "This photo does not contain a pixel buffer.") }
    return pixelBuffer
  }

  /// The pointer is valid only during `body`. Planar pixel buffers require native plane access.
  public func withUnsafeBytes<Result>(_ body: (UnsafeRawBufferPointer) throws -> Result) throws -> Result {
    let pixelBuffer = try getPixelBuffer()
    return try pixelBuffer.withReadOnlyBytes(body)
  }

  public func getFileData() throws -> Data {
    guard let data = photo.fileDataRepresentation() else {
      throw CameraError(message: "Failed to get the photo's file data.")
    }
    return data
  }

  public func getFileDataAsync() async throws -> Data {
    try await Self.processingQueue.perform { try self.getFileData() }
  }

  public func saveToFileAsync(path: String) async throws {
    try await Self.fileQueue.perform {
      try self.getFileData().write(to: URL(fileURLWithPath: path))
    }
  }

  public func saveToTemporaryFileAsync() async throws -> String {
    try await Self.fileQueue.perform {
      let fileType = try self.containerFormat.toUTType()
      let file = try URL.createTempURL(fileType: fileType)
      try self.getFileData().write(to: file)
      return file.path
    }
  }

  public func toImage() throws -> UIImage {
    guard let cgImage = photo.cgImageRepresentation() else {
      if isRawPhoto { throw CameraError(message: "Raw photos cannot be converted to UIImage.") }
      throw CameraError(message: "Failed to get the photo's image data.")
    }
    return UIImage(cgImage: cgImage, scale: 1, orientation: metadata.uiImageOrientation)
  }

  public func toImageAsync() async throws -> UIImage {
    try await Self.processingQueue.perform { try self.toImage() }
  }
}
