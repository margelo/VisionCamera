///
/// PhotoOutput.swift
/// VisionCamera
/// Copyright © 2025 Marc Rousavy @ Margelo
///

import AVFoundation
import Foundation
import UIKit

/// The ``PhotoOutput`` allows capturing ``Photo``s
/// in-memory, as well as directly to a file.
///
/// In-memory ``Photo``s can be converted to Images for immediate
/// display, and/or saved to a file (or the media gallery) later on.
public final class PhotoOutput: CameraOutput, NativeCameraOutput {
  private let queue = DispatchQueue(label: "com.margelo.camera.photo", qos: .userInitiated)
  private var captures: [Int64: CapturePhotoDelegate] = [:]
  private let options: PhotoOutputOptions
  /// The media type of the content being streamed
  /// by this ``CameraOutput``.
  public let mediaType: MediaType = .video
  /// Whether the Camera Session must connect an audio input to this output.
  public let requiresAudioInput: Bool = false
  // TODO: If depth data delivery is configured, we probably should return `true` here
  /// Whether the Camera Session must select an active depth format for this output.
  public let requiresDepthFormat: Bool = false
  /// The underlying AVFoundation output connected to the Camera Session.
  public let output: AVCapturePhotoOutput

  /// Get whether this ``PhotoOutput`` supports
  /// capturing depth data alongside with a normal ``Photo``,
  /// e.g. for portrait effects matte.
  /// See ``CapturePhotoSettings/enableDepthData``
  public var supportsDepthDataDelivery: Bool {
    return output.isDepthDataDeliverySupported
  }

  /// get whether this ``PhotoOutput`` supports
  /// delivering camera calibration data, e.g. for reconstructing
  /// lens-distortion or geometry.
  /// See ``CapturePhotoSettings/enableCameraCalibrationDataDelivery``
  public var supportsCameraCalibrationDataDelivery: Bool {
    return output.isCameraCalibrationDataDeliverySupported
  }
  /// Gets or sets the output orientation of this ``CameraOutput``.
  ///
  /// Individual implementations of ``CameraOutput``
  /// may choose different strategies for implementing
  /// output orientation, for example:
  /// - A Photo output might apply orientation via EXIF flags.
  /// - A Video output might apply orientation via track transform metadata.
  /// - A Preview output might apply orientation via view transforms.
  /// - A Frame output might not apply orientation and only pass it as a
  /// property via the `Frame` object, unless explicitly configured to
  /// physically rotate buffers.
  public var outputOrientation: CameraOrientation = .up {
    didSet {
      guard let connection = output.connection(with: .video) else { return }
      // TODO: Should we apply that within the CameraSession's DispatchQueue? Batch it?
      try? connection.setOrientation(outputOrientation)
    }
  }
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

  /// The stream type used when negotiating this output's target resolution.
  public var streamType: StreamType = .photo
  /// The resolution rule negotiated with the other outputs and the connection's ordered ``Constraint``s.
  public var targetResolution: ResolutionRule {
    return .closestTo(options.targetResolution)
  }

  /// Creates a Camera output with the given options.
  public init(options: PhotoOutputOptions = .init()) {
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

  /// Applies mirroring and orientation settings to this output's current connection.
  ///
  /// ``CameraSession`` calls this method within its configuration batch. Native output integrations must call it on the owning session's configuration queue.
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

  /// Captures a ``Photo`` using the given ``CapturePhotoSettings``.
  ///
  /// The returned Photo owns its native image data. Release references when the Photo is no longer needed.
  /// Capture and callback delivery run on this output's serial capture queue. Move UIKit work to the main actor.
  ///
  /// - Parameter settings: Settings for this Photo capture.
  /// - Parameter callbacks: Optional callbacks for capture progress and a preview image.
  /// - Returns: The captured Photo, after processing succeeds.
  /// - Throws: If settings cannot be applied or AVFoundation fails to capture or process the Photo.
  ///
  /// ```swift
  /// let photo = try await photoOutput.capturePhoto(settings: CapturePhotoSettings(flashMode: .on))
  /// ```
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

  /// Captures a Photo and writes it to a temporary file
  /// using the given ``CapturePhotoSettings``.
  ///
  /// ```swift
  /// let file = try await photoOutput.capturePhotoToFile(settings: CapturePhotoSettings(flashMode: .on))
  /// ```
  ///
  /// The returned ``PhotoFile`` contains a filesystem path. Capture callbacks run on this output's serial capture queue. File encoding and writing can throw.
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

  /// Asynchronously prepares the ``PhotoOutput``
  /// with the given `settings` array to improve capture
  /// responsiveness for subsequent ``PhotoOutput/capturePhoto(settings:callbacks:)``
  /// calls when called with any of the same ``CapturePhotoSettings``
  /// that have been prepared via this method.
  ///
  /// It is recommended to always call this with a few common
  /// settings you expect to be used for ``PhotoOutput/capturePhoto(settings:callbacks:)``
  /// later on.
  ///
  /// It is perfectly fine to not call ``PhotoOutput/prepareSettings(settings:)``
  /// when using Photo capture, but ``PhotoOutput/capturePhoto(settings:callbacks:)`` may
  /// allocate buffers that cause higher latency on initial calls when aiming for quality.
  ///
  /// ```swift
  /// try await photoOutput.prepareSettings(settings: [
  ///   CapturePhotoSettings(flashMode: .off, enableDistortionCorrection: true),
  ///   CapturePhotoSettings(flashMode: .on, enableDistortionCorrection: false)
  /// ])
  /// ```
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
