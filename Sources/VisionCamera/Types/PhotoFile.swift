// Copyright © 2025 Marc Rousavy @ Margelo

import CoreMedia
import Foundation

/// Represents a Photo captured by
/// ``PhotoOutput/capturePhotoToFile(settings:callbacks:)``
/// and written to a File.
public struct PhotoFile: Equatable, Sendable {
  /// The file URL of the captured photo.
  public var fileURL: URL
  /// The width of the captured Photo, in pixels.
  public var width: Int
  /// The height of the captured Photo, in pixels.
  public var height: Int
  /// The ``CameraOrientation`` the Photo was captured in.
  ///
  /// The orientation is applied lazily through the file's EXIF metadata.
  public var orientation: CameraOrientation
  /// Whether the captured Photo is mirrored along its vertical axis.
  public var isMirrored: Bool
  /// The timestamp at which the Photo was captured, using the system's
  /// host clock.
  public var timestamp: CMTime
  /// Whether the captured Photo is a RAW photo.
  public var isRaw: Bool
  /// The ``PhotoContainerFormat`` of the captured Photo.
  public var containerFormat: PhotoContainerFormat

  /// Describes a captured photo file and its dimensions, orientation, and capture metadata.
  ///
  /// - Parameters:
  ///   - fileURL: The file URL of the captured photo.
  ///   - width: The width of the captured Photo, in pixels.
  ///   - height: The height of the captured Photo, in pixels.
  ///   - orientation: The ``CameraOrientation`` the Photo was captured in.
  ///   - isMirrored: Whether the captured Photo is mirrored along its vertical axis.
  ///   - timestamp: The timestamp at which the Photo was captured, using the system's host clock.
  ///   - isRaw: Whether the captured Photo is a RAW photo.
  ///   - containerFormat: The ``PhotoContainerFormat`` of the captured Photo.
  public init(
    fileURL: URL,
    width: Int,
    height: Int,
    orientation: CameraOrientation,
    isMirrored: Bool,
    timestamp: CMTime,
    isRaw: Bool,
    containerFormat: PhotoContainerFormat
  ) {
    self.fileURL = fileURL
    self.width = width
    self.height = height
    self.orientation = orientation
    self.isMirrored = isMirrored
    self.timestamp = timestamp
    self.isRaw = isRaw
    self.containerFormat = containerFormat
  }
}
