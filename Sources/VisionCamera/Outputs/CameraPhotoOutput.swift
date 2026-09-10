///
/// CameraPhotoOutput.swift
/// VisionCamera
/// Copyright © 2025 Marc Rousavy @ Margelo
///

import AVFoundation
import Foundation
import UIKit

public final class CameraPhotoOutput: CameraOutput, NativeCameraOutput {
  private let queue = DispatchQueue(label: "com.margelo.camera.photo", qos: .userInitiated)
  private var captures: [Int64: CapturePhotoDelegate] = [:]
  private let options: PhotoOutputOptions
  public let mediaType: MediaType = .video
  public let requiresAudioInput: Bool = false
  // TODO: If depth data delivery is configured, we probably should return `true` here
  public let requiresDepthFormat: Bool = false
  public let output: AVCapturePhotoOutput

  public var supportsDepthDataDelivery: Bool {
    return output.isDepthDataDeliverySupported
  }

  public var supportsCameraCalibrationDataDelivery: Bool {
    return output.isCameraCalibrationDataDeliverySupported
  }
  public var outputOrientation: CameraOrientation = .up {
    didSet {
      guard let connection = output.connection(with: .video) else { return }
      // TODO: Should we apply that within the CameraSession's DispatchQueue? Batch it?
      try? connection.setOrientation(outputOrientation)
    }
  }
  public var currentResolution: Size? {
    // Reads back what `configure(config:)` pinned via
    // `output.maxPhotoDimensions = format.supportedMaxPhotoDimensions.nearest(...)`.
    if #available(iOS 16.0, *) {
      let dims = output.maxPhotoDimensions
      return Size(width: Double(dims.width), height: Double(dims.height))
    }
    guard let device = output.connections.first?.deviceInput?.device else {
      return nil
    }
    let dims = device.activeFormat.highResolutionStillImageDimensions
    return Size(width: Double(dims.width), height: Double(dims.height))
  }

  public var streamType: StreamType = .photo
  public var targetResolution: ResolutionRule {
    return .closestTo(options.targetResolution)
  }

  public init(options: PhotoOutputOptions) throws {
    self.output = AVCapturePhotoOutput()
    self.options = options

    output.maxPhotoQualityPrioritization = options.qualityPrioritization.toAVQualityPrioritization()

    if options.containerFormat == .dng {
      // If we capture RAW photos, try using Apple ProRAW. If not, Bayer14 RAW will be used.
      output.isAppleProRAWEnabled = output.isAppleProRAWSupported
    }

    if #available(iOS 26, *),
      output.isCameraSensorOrientationCompensationSupported
    {
      // Don't rotate Photo buffers - we handle orientation later on in file capture or toImage().
      output.isCameraSensorOrientationCompensationEnabled = false
    }

    // Prepare the default Photo Settings to make the pipeline ready - some things (like flashMode)
    // might change on a per-capture basis, but containerFormat and preview size is already known
    // and can be prepared already.
    try? prepareDefaultPhotoSettings()
  }

  public func configure(config: OutputConfiguration) {
    guard let connection = output.connection(with: .video) else {
      return
    }
    try? connection.setOrientation(outputOrientation)
    try? connection.setMirrorMode(config.mirrorMode)

    if #available(iOS 16.0, *) {
      // Configure PhotoOutput to the currently selected Format's max photo size
      if let nativeDevice = connection.deviceInput {
        let format = nativeDevice.device.activeFormat
        let targetResolution = options.targetResolution.toCMVideoDimensions()
        let nearestPhotoDimension = format.supportedMaxPhotoDimensions.nearest(to: targetResolution)
        if let nearestPhotoDimension,
          output.maxPhotoDimensions != nearestPhotoDimension
        {
          // Target max photo dimensions have changed, re-configure
          output.maxPhotoDimensions = nearestPhotoDimension
          try? prepareDefaultPhotoSettings()
        }
      }
    }
  }

  private func prepareDefaultPhotoSettings() throws {
    // Create default capture settings
    let settings = CapturePhotoSettings(
      flashMode: .off,
      enableShutterSound: true,
      enableDepthData: false,
      enableRedEyeReduction: true,
      enableCameraCalibrationDataDelivery: false,
      enableDistortionCorrection: false,
      enableVirtualDeviceFusion: true,
      location: nil)
    let avSettings = try settings.toAVCapturePhotoSettings(for: output, withOptions: options)
    // Prepare the AVCapturePhotoOutput for those settings so coming up captures are faster
    self.output.setPreparedPhotoSettingsArray([avSettings])
  }

  public func capturePhoto(
    settings: CapturePhotoSettings = .init(),
    callbacks: CapturePhotoCallbacks = .init()
  ) async throws -> Photo {
    try await withCheckedThrowingContinuation { continuation in
      queue.async(
        execute: DispatchWorkItem {
          do {
            guard self.output.connection(with: .video) != nil else {
              throw CameraError(message: "PhotoOutput is not yet connected to the CameraSession!")
            }
            let captureSettings = try settings.toAVCapturePhotoSettings(for: self.output, withOptions: self.options)
            let id = captureSettings.uniqueID
            let resultingFormat = PhotoContainerFormat(targetFormat: self.options.containerFormat)
            let delegate = CapturePhotoDelegate(
              queue: self.queue,
              onCaptured: { photo, metadata in
                if self.options.previewImageTargetSize != nil,
                  let onPreviewImageAvailable = callbacks.onPreviewImageAvailable,
                  let preview = photo.previewCGImageRepresentation()
                {
                  onPreviewImageAvailable(UIImage(cgImage: preview, scale: 1, orientation: metadata.uiImageOrientation))
                }
                let result = Photo(photo: photo, metadata: metadata, containerFormat: resultingFormat)
                continuation.resume(returning: result)
              },
              onError: { continuation.resume(throwing: $0) },
              onFinished: { self.captures[id] = nil },
              callbacks: callbacks)
            self.captures[id] = delegate
            self.output.capturePhoto(with: captureSettings, delegate: delegate)
          } catch {
            continuation.resume(throwing: error)
          }
        })
    }
  }

  public func capturePhotoToFile(
    settings: CapturePhotoSettings = .init(),
    callbacks: CapturePhotoCallbacks = .init()
  ) async throws -> PhotoFile {
    let photo = try await capturePhoto(settings: settings, callbacks: callbacks)
    let filePath = try await photo.saveToTemporaryFileAsync()
    return PhotoFile(
      filePath: filePath,
      width: photo.width,
      height: photo.height,
      orientation: photo.orientation,
      isMirrored: photo.isMirrored,
      timestamp: photo.timestamp,
      isRawPhoto: photo.isRawPhoto,
      containerFormat: photo.containerFormat)
  }

  public func prepareSettings(settings: [CapturePhotoSettings]) async throws {
    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
      queue.async(
        execute: DispatchWorkItem {
          do {
            let captureSettings = try settings.map {
              try $0.toAVCapturePhotoSettings(for: self.output, withOptions: self.options)
            }
            self.output.setPreparedPhotoSettingsArray(captureSettings) { prepared, error in
              if let error {
                continuation.resume(throwing: error)
              } else if prepared {
                continuation.resume()
              } else {
                continuation.resume(throwing: CameraError(message: "Settings preparation was cancelled."))
              }
            }
          } catch {
            continuation.resume(throwing: error)
          }
        })
    }
  }
}
