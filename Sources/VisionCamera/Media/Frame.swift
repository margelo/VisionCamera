// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation
import Foundation

/// A retained camera sample. Use a frame on one queue at a time.
public final class Frame {
  public private(set) var sampleBuffer: CMSampleBuffer?
  public let metadata: MediaSampleMetadata
  private var planesCached: [FramePlane]?

  public init(buffer: CMSampleBuffer, metadata: MediaSampleMetadata) {
    self.sampleBuffer = buffer
    self.metadata = metadata
  }

  public var pixelBuffer: CVPixelBuffer? { sampleBuffer?.imageBuffer }
  public var memorySize: Int { pixelBuffer?.memorySize ?? 0 }
  public var timestamp: Double { metadata.timestamp.seconds }
  public var isMirrored: Bool { metadata.isMirrored }
  public var orientation: CameraOrientation { metadata.orientation }
  public var width: Double { pixelBuffer.map { Double(CVPixelBufferGetWidth($0)) } ?? 0 }
  public var height: Double { pixelBuffer.map { Double(CVPixelBufferGetHeight($0)) } ?? 0 }
  public var bytesPerRow: Double { pixelBuffer.map { Double(CVPixelBufferGetBytesPerRow($0)) } ?? 0 }
  public var isValid: Bool { sampleBuffer?.isValid ?? false }
  public var isPlanar: Bool { pixelBuffer.map { CVPixelBufferIsPlanar($0) } ?? false }
  public var hasPixelBuffer: Bool { pixelBuffer != nil }
  public var hasNativeBuffer: Bool { pixelBuffer != nil }

  public var pixelFormat: PixelFormat {
    guard let pixelBuffer else { return .unknown }
    return PixelFormat(osType: CVPixelBufferGetPixelFormatType(pixelBuffer))
  }

  public var cameraIntrinsicMatrix: [Double]? {
    sampleBuffer?.getCameraIntrinsicMatrix()?.toDoubleArray()
  }

  /// Releases this frame's references. Previously retained native buffers and planes remain valid.
  /// ARC releases the same references if the frame is deallocated without calling this method.
  public func dispose() {
    sampleBuffer = nil
    planesCached = nil
  }

  public func getPlanes() throws -> [FramePlane] {
    let pixelBuffer = try getPixelBuffer()
    if let planesCached { return planesCached }
    let planes = try (0..<CVPixelBufferGetPlaneCount(pixelBuffer)).map { index in
      try FramePlane(buffer: pixelBuffer, planeIndex: index)
    }
    planesCached = planes
    return planes
  }

  public func getPixelBuffer() throws -> CVPixelBuffer {
    guard isValid else { throw CameraError(message: "This frame has been disposed or invalidated.") }
    guard let pixelBuffer else { throw CameraError(message: "This frame does not contain a pixel buffer.") }
    return pixelBuffer
  }

  public func getNativeBuffer() throws -> CVPixelBuffer { try getPixelBuffer() }

  /// The pointer is valid only during `body`. Copy its bytes to retain them afterward.
  /// Planar buffers must be read through `getPlanes()`.
  public func withUnsafeBytes<Result>(_ body: (UnsafeRawBufferPointer) throws -> Result) throws -> Result {
    let pixelBuffer = try getPixelBuffer()
    return try pixelBuffer.withReadOnlyBytes(body)
  }

  public func convertCameraPointToFramePoint(cameraPoint: Point) throws -> Point {
    let pixelBuffer = try getPixelBuffer()
    let matrix = FrameCoordinateSystemConverter.getCameraToFrameMatrix(
      pixelBuffer: pixelBuffer, orientation: orientation, isMirrored: isMirrored)
    return cameraPoint.applying(matrix)
  }

  public func convertFramePointToCameraPoint(framePoint: Point) throws -> Point {
    let pixelBuffer = try getPixelBuffer()
    let matrix = FrameCoordinateSystemConverter.getFrameToCameraMatrix(
      pixelBuffer: pixelBuffer, orientation: orientation, isMirrored: isMirrored)
    return framePoint.applying(matrix)
  }
}
