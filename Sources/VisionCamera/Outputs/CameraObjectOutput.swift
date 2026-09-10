///
/// CameraObjectOutput.swift
/// VisionCamera
/// Copyright © 2025 Marc Rousavy @ Margelo
///

import AVFoundation
import Foundation

public final class CameraObjectOutput: CameraOutput, NativeCameraOutput {
  private let queue = DispatchQueue(label: "com.margelo.camera.object-scanner")
  private let delegate: MetadataDelegate
  private let options: ObjectOutputOptions
  public let mediaType: MediaType = .metadata
  public let output: AVCaptureMetadataOutput
  public let requiresAudioInput: Bool = false
  public let requiresDepthFormat: Bool = false
  public var outputOrientation: CameraOrientation = .up {
    didSet {
      guard let connection = output.connection(with: .metadataObject) else { return }
      // TODO: Should we apply that within the CameraSession's DispatchQueue? Batch it?
      try? connection.setOrientation(outputOrientation)
    }
  }
  public var currentResolution: Size? {
    guard let connection = output.connection(with: .metadataObject) else { return nil }
    return connection.inputStreamResolution
  }

  public var streamType: StreamType = .video
  public var targetResolution: ResolutionRule = .any

  public init(options: ObjectOutputOptions) {
    self.options = options
    self.output = AVCaptureMetadataOutput()
    self.delegate = MetadataDelegate()

    output.setMetadataObjectsDelegate(delegate, queue: queue)
  }

  public func configure(config: OutputConfiguration) {
    guard let connection = output.connection(with: .metadataObject) else {
      return
    }
    try? connection.setOrientation(outputOrientation)
    try? connection.setMirrorMode(config.mirrorMode)

    // Enable all the types that are supported
    let filteredObjectTypes = options.enabledObjectTypes
      .compactMap { $0.toAVMetadataObjectType() }
      .filter { output.availableMetadataObjectTypes.contains($0) }
    output.metadataObjectTypes = filteredObjectTypes
  }

  public func setOnObjectsScannedCallback(onObjectsScanned: (([any ScannedObject]) -> Void)?) async {
    await queue.perform {
      if let onObjectsScanned {
        self.delegate.onMetadataObjects = { objects in
          onObjectsScanned(objects.map { Self.createScannedObject(from: $0) })
        }
      } else {
        self.delegate.onMetadataObjects = nil
      }
    }
  }

  public static func createScannedObject(from object: AVMetadataObject)
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
