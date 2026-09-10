///
/// ObjectOutput.swift
/// VisionCamera
/// Copyright © 2025 Marc Rousavy @ Margelo
///

import AVFoundation
import Foundation

/// The ``ObjectOutput`` allows scanning various
/// objects (``ScannedObject``), faces (``ScannedFace``),
/// or machine-readable codes (``ScannedCode``) in the Camera, using
/// AVFoundation metadata detection.
///
/// ```swift
/// let objectOutput = ObjectOutput(
///   options: ObjectOutputOptions(enabledObjectTypes: [.qr])
/// )
/// await objectOutput.setOnObjectsScannedCallback { objects in
///   for case let code as ScannedCode in objects {
///     print(code.value ?? "")
///   }
/// }
/// ```
public final class ObjectOutput: CameraOutput, NativeCameraOutput {
  private let queue = DispatchQueue(label: "com.margelo.camera.object-scanner")
  private let delegate: MetadataDelegate
  private let options: ObjectOutputOptions
  /// The media type of the content being streamed
  /// by this ``CameraOutput``.
  public let mediaType: MediaType = .metadata
  /// The underlying AVFoundation output connected to the Camera Session.
  public let output: AVCaptureMetadataOutput
  /// Whether the Camera Session must connect an audio input to this output.
  public let requiresAudioInput: Bool = false
  /// Whether the Camera Session must select an active depth format for this output.
  public let requiresDepthFormat: Bool = false
  /// Metadata uses the unrotated capture-device coordinate system.
  ///
  /// Use ``PreviewView/convertScannedObjectCoordinatesToViewCoordinates(scannedObject:)`` to account
  /// for preview rotation, mirroring, and scaling when displaying detected objects.
  public let outputOrientation: CameraOrientation = .up
  /// The resolution that the underlying capture pipeline has resolved
  /// this ``CameraOutput`` to, in sensor-native (un-rotated) pixels,
  /// or `nil` if the output has not yet been connected to a
  /// ``CameraSession``.
  ///
  /// The selected ``Size`` may differ from the requested
  /// ``Size`` (e.g. from ``PhotoOutputOptions/targetResolution``),
  /// as the ``CameraSession`` negotiates resolutions across
  /// attached ``CameraOutput``s, connected ``CameraDevice``
  /// capabilities, and enabled ``Constraint``s.
  ///
  /// For outputs that are not pixel-based (e.g. metadata-only outputs),
  /// this reports the resolution of the upstream video stream feeding
  /// the output, or `nil` if no video input is attached.
  public var currentResolution: Size? {
    guard let connection = output.connection(with: .metadataObject) else { return nil }
    return connection.inputStreamResolution
  }

  /// The stream type used when negotiating this output's target resolution.
  public let streamType: StreamType = .video
  /// The resolution rule negotiated with the other outputs and the connection's ordered ``Constraint``s.
  public var targetResolution: ResolutionRule = .any

  /// Creates a Camera output with the given options.
  public init(options: ObjectOutputOptions) {
    self.options = options
    self.output = AVCaptureMetadataOutput()
    self.delegate = MetadataDelegate()

    output.setMetadataObjectsDelegate(delegate, queue: queue)
  }

  /// Applies supported metadata types to this output's current connection.
  ///
  /// - Throws: If a requested metadata type is unavailable or mirroring is explicitly enabled.
  /// Metadata coordinates remain in the unrotated capture-device coordinate system.
  ///
  /// ``CameraSession`` calls this method within its configuration batch. Native output integrations must call it on the owning session's configuration queue.
  public func configure(config: OutputConfiguration) throws {
    guard config.mirrorMode != .on else {
      throw CameraError(message: "Metadata uses unmirrored capture-device coordinates. Convert objects to preview coordinates when displaying them.")
    }
    guard output.connection(with: .metadataObject) != nil else {
      return
    }

    let requestedTypes = Array(Set(options.enabledObjectTypes))
    let unsupportedTypes = requestedTypes.filter { !output.availableMetadataObjectTypes.contains($0) }
    guard unsupportedTypes.isEmpty else {
      throw CameraError(message: "Metadata types are unavailable on this connection: \(unsupportedTypes.map(\.rawValue)).")
    }
    output.metadataObjectTypes = requestedTypes
  }

  /// Sets the `onObjectsScanned` callback.
  ///
  /// Registration and callback delivery are serialized on this output's owning queue. Pass `nil` to remove the callback. This method returns after registration is applied. Move UIKit work to the main actor.
  public func setOnObjectsScannedCallback(onObjectsScanned: (([any ScannedObject]) -> Void)?) async {
    await queue.perform {
      if let onObjectsScanned {
        self.delegate.onMetadataObjects = { objects in
          onObjectsScanned(objects.map { Self.scannedObject(from: $0) })
        }
      } else {
        self.delegate.onMetadataObjects = nil
      }
    }
  }

  /// Wraps an AVFoundation metadata object as a ``ScannedCode``, ``ScannedFace``, or ``MetadataObject`` according to its native type.
  public static func scannedObject(from object: AVMetadataObject)
    -> any ScannedObject
  {
    switch object {
    case let code as AVMetadataMachineReadableCodeObject:
      // Code
      return ScannedCode(object: code)
    case let face as AVMetadataFaceObject:
      // Face
      return ScannedFace(object: face)
    default:
      // Any other AVMetadataObject
      return MetadataObject(object: object)
    }
  }
}
