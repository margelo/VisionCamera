// Copyright © 2025 Marc Rousavy @ Margelo

/// Represents a Photo captured by
/// ``PhotoOutput/capturePhotoToFile(settings:callbacks:)``
/// and written to a File.
public struct PhotoFile: Equatable, Sendable {
  /// The path of the file.
  /// This is a filesystem path, not a `file://` URL.
  public var filePath: String
  /// The width of the captured Photo, in pixels.
  public var width: Double
  /// The height of the captured Photo, in pixels.
  public var height: Double
  /// The ``CameraOrientation`` the Photo was captured in.
  ///
  /// The orientation is applied lazily through the file's EXIF metadata.
  public var orientation: CameraOrientation
  /// Whether the captured Photo is mirrored along its vertical axis.
  public var isMirrored: Bool
  /// The timestamp at which the Photo was captured, using the system's
  /// host clock, in seconds.
  public var timestamp: Double
  /// Whether the captured Photo is a RAW photo.
  public var isRawPhoto: Bool
  /// The ``PhotoContainerFormat`` of the captured Photo.
  public var containerFormat: PhotoContainerFormat

  /// Describes a captured photo file and its dimensions, orientation, and capture metadata.
  ///
  /// - Parameters:
  ///   - filePath: The path of the file. This is a filesystem path, not a `file://` URL.
  ///   - width: The width of the captured Photo, in pixels.
  ///   - height: The height of the captured Photo, in pixels.
  ///   - orientation: The ``CameraOrientation`` the Photo was captured in.
  ///   - isMirrored: Whether the captured Photo is mirrored along its vertical axis.
  ///   - timestamp: The timestamp at which the Photo was captured, using the system's host clock, in seconds.
  ///   - isRawPhoto: Whether the captured Photo is a RAW photo.
  ///   - containerFormat: The ``PhotoContainerFormat`` of the captured Photo.
  public init(
    filePath: String,
    width: Double,
    height: Double,
    orientation: CameraOrientation,
    isMirrored: Bool,
    timestamp: Double,
    isRawPhoto: Bool,
    containerFormat: PhotoContainerFormat
  ) {
    self.filePath = filePath
    self.width = width
    self.height = height
    self.orientation = orientation
    self.isMirrored = isMirrored
    self.timestamp = timestamp
    self.isRawPhoto = isRawPhoto
    self.containerFormat = containerFormat
  }
}
