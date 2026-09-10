// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation
import Foundation

/// A Camera Session configuration that the hardware or connected outputs cannot support.
///
/// Session configuration also propagates native AVFoundation errors and task cancellation unchanged.
public enum ConfigurationError: Error, LocalizedError {
  /// The device cannot capture from multiple Cameras at the same time.
  case multiCamUnsupported
  /// A single-camera session cannot accept the requested number of input connections.
  case multipleInputsRequireMultiCam(count: Int)
  /// No Camera is available at the requested position.
  case cameraUnavailable(position: TargetCameraPosition)
  /// The device has no available microphone.
  case microphoneUnavailable
  /// The requested Camera input has not been attached to the session.
  case inputNotConnected(deviceID: String)
  /// AVFoundation cannot add this input to the session.
  case inputRejected(deviceID: String)
  /// A custom output does not implement a native Camera output protocol.
  case unsupportedOutput(outputType: String)
  /// An output is already connected to another session.
  case outputAlreadyConnected(outputType: String)
  /// AVFoundation cannot add this output to the session.
  case outputRejected(outputType: String)
  /// An operation requires an output connected to a Camera Session.
  case outputNotConnected
  /// A Camera input has no port for the output's media type.
  case inputPortUnavailable(deviceID: String, mediaType: AVMediaType)
  /// An audio connection requires a microphone input attached to the session.
  case audioInputNotConnected
  /// The microphone input has no audio port.
  case audioPortUnavailable
  /// AVFoundation cannot add a connection for this media type.
  case connectionRejected(mediaType: AVMediaType)
  /// The Camera has no available capture formats.
  case noFormats(deviceID: String)
  /// No capture format provides the requested depth output.
  case depthCaptureUnsupported(deviceID: String)
  /// No capture format supports this Camera in a Multi-Cam session.
  case multiCamCaptureUnsupported(deviceID: String)
  /// No capture format supports all of the requested outputs together.
  case incompatibleOutputs(deviceID: String)
  /// The connection cannot apply the requested orientation.
  case orientationUnsupported(CameraOrientation)
  /// The connection cannot mirror its video stream.
  case mirroringUnsupported
  /// A resolution constraint references an output without resolution negotiation support.
  case resolutionNegotiationUnsupported(outputType: String)
  /// The format does not provide a resolution for this stream type.
  case resolutionsUnavailable(streamType: StreamType)

  /// The active capture format does not support the selected frame rate.
  case frameRateUnsupported
  /// The selected video stabilization mode is unavailable on this OS version.
  case videoStabilizationUnavailable
  /// The selected preview stabilization mode is unavailable on this OS version.
  case previewStabilizationUnavailable
  /// The selected color space is unavailable for the active capture format.
  case colorSpaceUnsupported
  /// Preview-sized FrameOutput buffers require iOS 17 or later.
  case previewSizedBuffersRequireIOS17
  /// The connected FrameOutput does not support camera intrinsic matrix delivery.
  case intrinsicMatrixDeliveryUnsupported
  /// Metadata uses unmirrored capture-device coordinates. Convert objects to preview coordinates when displaying them.
  case metadataMirroringUnsupported
  /// Frame rate must be a finite value greater than zero.
  case invalidFrameRate
  /// The capture format does not report a supported frame rate range.
  case frameRateRangesUnavailable
  /// The capture format does not report a supported color space that VisionCamera can configure.
  case colorSpacesUnavailable
  /// The requested metadata types are unavailable on the connected output.
  case metadataTypesUnavailable
  /// The requested Core Video pixel format is unavailable on the connected output.
  case pixelFormatUnavailable

  /// A description of the unsupported session configuration.
  public var errorDescription: String? {
    switch self {
    case .frameRateUnsupported:
      return "The active capture format does not support the selected frame rate."
    case .videoStabilizationUnavailable:
      return "The selected video stabilization mode is unavailable on this OS version."
    case .previewStabilizationUnavailable:
      return "The selected preview stabilization mode is unavailable on this OS version."
    case .colorSpaceUnsupported:
      return "The selected color space is unavailable for the active capture format."
    case .previewSizedBuffersRequireIOS17:
      return "Preview-sized FrameOutput buffers require iOS 17 or later."
    case .intrinsicMatrixDeliveryUnsupported:
      return "The connected FrameOutput does not support camera intrinsic matrix delivery."
    case .metadataMirroringUnsupported:
      return "Metadata uses unmirrored capture-device coordinates. Convert objects to preview coordinates when displaying them."
    case .invalidFrameRate:
      return "Frame rate must be a finite value greater than zero."
    case .frameRateRangesUnavailable:
      return "The capture format does not report a supported frame rate range."
    case .colorSpacesUnavailable:
      return "The capture format does not report a supported color space that VisionCamera can configure."
    case .metadataTypesUnavailable:
      return "The requested metadata types are unavailable on the connected output."
    case .pixelFormatUnavailable:
      return "The requested Core Video pixel format is unavailable on the connected output."

    case .multiCamUnsupported:
      return "This device does not support multi-camera sessions."
    case .multipleInputsRequireMultiCam(let count):
      return "A single-camera session cannot accept \(count) input connections. Create CameraSession(isMultiCamEnabled: true) to use multiple inputs."
    case .cameraUnavailable(let position):
      return "No Camera is available at position \(position)."
    case .microphoneUnavailable:
      return "This device has no available microphone."
    case .inputNotConnected(let deviceID):
      return "Camera input \(deviceID) is not connected to this session."
    case .inputRejected(let deviceID):
      return "Camera input \(deviceID) cannot be added to this session."
    case .unsupportedOutput(let outputType):
      return "Output \(outputType) must conform to NativeCameraOutput or NativePreviewViewOutput."
    case .outputAlreadyConnected(let outputType):
      return "Output \(outputType) is already connected to another Camera Session."
    case .outputRejected(let outputType):
      return "Output \(outputType) cannot be added to this Camera Session."
    case .outputNotConnected:
      return "Connect the output to a Camera Session before performing this operation."
    case .inputPortUnavailable(let deviceID, let mediaType):
      return "Camera input \(deviceID) has no port for media type \(mediaType)."
    case .audioInputNotConnected:
      return "Connect a microphone input to the session before creating an audio connection."
    case .audioPortUnavailable:
      return "The microphone input has no audio port."
    case .connectionRejected(let mediaType):
      return "A connection for media type \(mediaType) cannot be added to this Camera Session."
    case .noFormats(let deviceID):
      return "Camera \(deviceID) has no available capture formats."
    case .depthCaptureUnsupported(let deviceID):
      return "Camera \(deviceID) has no capture format that supports depth output."
    case .multiCamCaptureUnsupported(let deviceID):
      return "Camera \(deviceID) has no capture format that supports a Multi-Cam session."
    case .incompatibleOutputs(let deviceID):
      return "Camera \(deviceID) has no capture format that supports all requested outputs."
    case .orientationUnsupported(let orientation):
      return "This connection does not support changing orientation to \(orientation)."
    case .mirroringUnsupported:
      return "This connection does not support video mirroring."
    case .resolutionNegotiationUnsupported(let outputType):
      return "Output \(outputType) must conform to ResolutionNegotiationParticipant to request a resolution."
    case .resolutionsUnavailable(let streamType):
      return "The capture format has no available resolutions for stream type \(streamType)."
    }
  }
}
