// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation
import Foundation
import UIKit

/// Represents a captured ``Photo`` in memory.
///
/// Photos can be captured with a ``PhotoOutput``, and can be saved to a file using ``Photo/saveToTemporaryFileAsync()``.
///
/// To display the photo to the user, use ``Photo/toImageAsync()`` and display the returned `UIImage` in a `UIImageView`.
///
/// The Photo retains its native image data until it is deallocated. Release references when you are no longer using it.
///
/// ```swift
/// let photo = try await photoOutput.capturePhoto(settings: .init())
/// let image = try await photo.toImageAsync()
/// // Assign to a UIImageView on the main actor.
/// imageView.image = image
///
/// let path = try await photo.saveToTemporaryFileAsync()
/// ```
public final class Photo {
  /// The retained native `AVCapturePhoto` containing the image and capture metadata.
  public let photo: AVCapturePhoto
  /// The timestamp, orientation, and mirroring metadata associated with this media sample.
  public let metadata: MediaSampleMetadata
  /// Get the ``PhotoContainerFormat`` of
  /// this ``Photo``.
  public let containerFormat: PhotoContainerFormat
  private static let processingQueue = DispatchQueue(label: "com.margelo.camera.photo-processing", qos: .userInitiated)
  private static let fileQueue = DispatchQueue(label: "com.margelo.camera.photo-files", qos: .utility)

  /// Creates a Photo that retains an existing `AVCapturePhoto`, its metadata, and its container format.
  public init(photo: AVCapturePhoto, metadata: MediaSampleMetadata, containerFormat: PhotoContainerFormat) {
    self.photo = photo
    self.metadata = metadata
    self.containerFormat = containerFormat
  }

  /// An estimate of the Photo's native memory usage in bytes, including its image, preview, and depth buffers.
  public var memorySize: Int { photo.memorySize }
  /// Represents the timestamp this ``Photo`` was
  /// captured at, using the system's host clock, in seconds.
  public var timestamp: Double { photo.timestamp.seconds }
  /// Gets whether this ``Photo`` is mirrored alongside the
  /// vertical axis.
  public var isMirrored: Bool { metadata.isMirrored }
  /// Gets the ``CameraOrientation`` this ``Photo`` was
  /// captured in.
  ///
  /// ``CameraOrientation`` will be applied lazily via EXIF
  /// flags, or when converting the ``Photo`` to an
  /// `UIImage`.
  public var orientation: CameraOrientation { metadata.orientation }
  /// Gets whether this ``Photo`` is a RAW photo (i.e.
  /// no processing has been applied), or a processed photo (e.g.
  /// JPEG).
  /// See ``Photo/containerFormat``
  public var isRawPhoto: Bool { photo.isRawPhoto }
  /// The retained native pixel buffer, if AVFoundation included one in the Photo.
  public var pixelBuffer: CVPixelBuffer? { photo.pixelBuffer }
  /// Get whether this Photo has a native pixel buffer attached to it. See ``Photo/getPixelBuffer()``.
  public var hasPixelBuffer: Bool { pixelBuffer != nil }
  /// Get the width of this ``Photo``, in pixels.
  public var width: Double { Double(size.width) }
  /// Get the height of this ``Photo``, in pixels.
  public var height: Double { Double(size.height) }

  /// Get the associated ``Depth`` data
  /// for this ``Photo`` if it has one.
  /// See ``CapturePhotoSettings/enableDepthData``
  public var depth: Depth? {
    photo.depthData.map { Depth(depthData: $0, metadata: metadata) }
  }

  /// The width and height of the Photo, in pixels.
  public var size: CMVideoDimensions {
    isRawPhoto ? photo.resolvedSettings.rawPhotoDimensions : photo.resolvedSettings.photoDimensions
  }

  /// Get the associated ``CameraCalibrationData``
  /// for this ``Photo`` if calibration data delivery
  /// was enabled.
  ///
  /// Native captures can include calibration data when configured for constituent photo delivery.
  public var calibrationData: CameraCalibrationData? {
    photo.cameraCalibrationData.map { CameraCalibrationData(calibrationData: $0) }
  }

  /// Get the Photo's native `CVPixelBuffer` without copying its pixels.
  ///
  /// The returned buffer remains valid independently of the Photo while the caller retains it.
  /// - Throws: If the Photo has no pixel buffer.
  public func getPixelBuffer() throws -> CVPixelBuffer {
    guard let pixelBuffer else { throw CameraError(message: "This photo does not contain a pixel buffer.") }
    return pixelBuffer
  }

  /// Provides scoped, read-only access to the Photo's non-planar pixel buffer.
  ///
  /// The buffer is locked for the duration of `body` and unlocked even if `body` throws. The pointer must not escape the closure. Copy the bytes into `Data` to keep them beyond the closure.
  /// - Throws: If the Photo has no pixel buffer, it is planar, locking fails, or `body` throws.
  public func withUnsafeBytes<Result>(_ body: (UnsafeRawBufferPointer) throws -> Result) throws -> Result {
    let pixelBuffer = try getPixelBuffer()
    return try pixelBuffer.withReadOnlyBytes(body)
  }

  /// Gets the raw file data of the ``Photo`` after
  /// processing and including EXIF flags.
  ///
  /// Returns owned `Data` that remains valid after this Photo is released.
  public func getFileData() throws -> Data {
    guard let data = photo.fileDataRepresentation() else {
      throw CameraError(message: "Failed to get the photo's file data.")
    }
    return data
  }

  /// Asynchronously gets the raw file data of
  /// the ``Photo`` after processing
  /// and including EXIF flags.
  ///
  /// Encoding runs on the shared serial Photo processing queue. Returns owned `Data` that remains valid after this Photo is released.
  public func getFileDataAsync() async throws -> Data {
    try await Self.processingQueue.perform { try self.getFileData() }
  }

  /// Asynchronously saves this Photo to a file at the given `path`, using this ``Photo/containerFormat``.
  ///
  /// - Parameter path: The full filesystem path, including filename and extension. Parent directories must exist. An existing file at this path is overwritten. This must be a filesystem path, not a `file://` URL.
  ///
  /// Encoding and writing run on the shared serial Photo file queue. Encoding and file-writing errors propagate to the caller.
  public func saveToFileAsync(path: String) async throws {
    try await Self.fileQueue.perform {
      try self.getFileData().write(to: URL(fileURLWithPath: path))
    }
  }

  /// Asynchronously saves this ``Photo`` to
  /// a temporary file using this ``Photo/containerFormat``,
  /// and returns the path it was saved at.
  ///
  /// The returned value is a filesystem path, not a `file://` URL.
  ///
  /// Encoding and writing run on the shared serial Photo file queue. Encoding and file-writing errors propagate to the caller.
  public func saveToTemporaryFileAsync() async throws -> String {
    try await Self.fileQueue.perform {
      let fileType = try self.containerFormat.toUTType()
      let file = try URL.createTempURL(fileType: fileType)
      try self.getFileData().write(to: file)
      return file.path
    }
  }

  /// Converts this ``Photo`` to an `UIImage`,
  /// possibly applying ``Photo/orientation`` and ``Photo/isMirrored``
  /// settings.
  /// - Throws: If the ``Photo`` is a raw photo (see ``Photo/isRawPhoto``)
  /// - Throws: If the ``Photo``'s Image data cannot be accessed
  public func toImage() throws -> UIImage {
    guard let cgImage = photo.cgImageRepresentation() else {
      if isRawPhoto { throw CameraError(message: "Raw photos cannot be converted to UIImage.") }
      throw CameraError(message: "Failed to get the photo's image data.")
    }
    return UIImage(cgImage: cgImage, scale: 1, orientation: metadata.uiImageOrientation)
  }

  /// Asynchronously converts this ``Photo`` to an `UIImage`,
  /// possibly applying ``Photo/orientation`` and ``Photo/isMirrored``
  /// settings.
  /// - Throws: If the ``Photo`` is a raw photo (see ``Photo/isRawPhoto``)
  /// - Throws: If the ``Photo``'s Image data cannot be accessed
  ///
  /// Conversion runs on the shared serial Photo processing queue. Conversion errors propagate to the caller.
  public func toImageAsync() async throws -> UIImage {
    try await Self.processingQueue.perform { try self.toImage() }
  }
}
