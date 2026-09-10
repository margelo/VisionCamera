import CoreVideo
import Foundation

/// A validation or conversion failure while accessing Camera media.
///
/// Native Apple errors from file I/O, sample-buffer creation, and rendering propagate unchanged when available.
public enum MediaError: Error, LocalizedError, Sendable {
  /// The sample buffer has been invalidated through Core Media.
  case invalidSampleBuffer
  /// The media sample does not contain an image buffer.
  case missingPixelBuffer
  /// A plane was requested from a non-planar pixel buffer.
  case planeAccessRequiresPlanarBuffer
  /// Contiguous byte access was requested for a planar pixel buffer.
  case nonPlanarPixelBufferRequired
  /// The plane index is outside the pixel buffer's available planes.
  case invalidPlaneIndex(index: Int, planeCount: Int)
  /// Core Video could not lock the pixel buffer for reading.
  case pixelBufferLockFailed(status: CVReturn)
  /// Core Video did not expose a CPU-accessible base address.
  case pixelBufferBaseAddressUnavailable
  /// A required Photo metadata entry is missing or has an unexpected type.
  case photoMetadataUnavailable(key: String)
  /// A Photo contains an EXIF orientation outside the defined range of 1 through 8.
  case invalidEXIFOrientation(UInt32)
  /// AVFoundation could not produce the Photo's encoded data.
  case photoDataUnavailable
  /// AVFoundation could not produce an image representation of the Photo.
  case photoImageUnavailable(isRaw: Bool)
  /// Core Image could not create an image from the depth data.
  case depthImageUnavailable
  /// Core Image could not render the image.
  case imageRenderingFailed
  /// The Photo's container format cannot be written to a file.
  case unsupportedPhotoContainerFormat(PhotoContainerFormat)
  /// The requested format is not supported for this depth data.
  case unsupportedDepthPixelFormat(DepthPixelFormat)
  /// A file operation received a URL that is not a file URL.
  case invalidFileURL(URL)
  /// The frame display layer failed without providing an underlying error.
  case frameRenderingFailed

  /// A description of the media operation that failed.
  public var errorDescription: String? {
    switch self {
    case .invalidSampleBuffer:
      return "The sample buffer has been invalidated."
    case .missingPixelBuffer:
      return "The media sample does not contain a pixel buffer."
    case .planeAccessRequiresPlanarBuffer:
      return "Plane access requires a planar pixel buffer."
    case .nonPlanarPixelBufferRequired:
      return "Access individual planes to read a planar pixel buffer's bytes."
    case .invalidPlaneIndex(let index, let planeCount):
      return "Pixel buffer plane index \(index) is outside the available \(planeCount) planes."
    case .pixelBufferLockFailed(let status):
      return "Core Video could not lock the pixel buffer for reading (status \(status))."
    case .pixelBufferBaseAddressUnavailable:
      return "The pixel buffer does not have a CPU-accessible base address."
    case .photoMetadataUnavailable(let key):
      return "The Photo's required metadata entry \(key) is missing or has an unexpected type."
    case .invalidEXIFOrientation(let value):
      return "The Photo contains an invalid EXIF orientation: \(value)."
    case .photoDataUnavailable:
      return "AVFoundation could not encode the Photo's file data."
    case .photoImageUnavailable(let isRaw):
      return isRaw ? "The RAW Photo has no processed image representation." : "AVFoundation could not create the Photo's image representation."
    case .depthImageUnavailable:
      return "Core Image could not create an image from the depth data."
    case .imageRenderingFailed:
      return "Core Image could not render the image."
    case .unsupportedPhotoContainerFormat(let format):
      return "Photo container format \(format) cannot be written to a file."
    case .unsupportedDepthPixelFormat(let format):
      return "Depth pixel format \(format) is not supported for this depth data."
    case .invalidFileURL(let url):
      return "Expected a file URL, received \(url)."
    case .frameRenderingFailed:
      return "The frame display layer could not render the sample buffer."
    }
  }
}
