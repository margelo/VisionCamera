// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation
import Foundation
import UIKit

/// The ``FrameConverter`` can convert ``Frame``s
/// and ``Depth`` to `UIImage`s.
public enum FrameConverter {
  private static let queue = DispatchQueue(label: "com.margelo.camera.image-conversion", qos: .userInitiated)

  /// Converts the given ``Frame`` to an `UIImage`.
  /// This renders the pixel buffer into a new image.
  ///
  /// - Throws: If the Frame is invalid (``Frame/isValid``).
  ///
  /// The returned `UIImage` includes the Frame's orientation and mirroring metadata. Throws if the Frame is disposed or conversion fails.
  public static func convertFrameToImage(frame: Frame) throws -> UIImage {
    guard let sampleBuffer = frame.sampleBuffer else {
      throw CameraError(message: "This frame has been disposed.")
    }
    return try sampleBuffer.toUIImage(orientation: frame.metadata.uiImageOrientation)
  }

  /// Asynchronously converts this ``Frame`` to an
  /// `UIImage`.
  /// This renders the pixel buffer into a new image.
  ///
  /// - Throws: If the Frame is invalid (``Frame/isValid``).
  ///
  /// Conversion runs on a shared serial queue. The sample buffer is retained before that queue hop. The returned `UIImage` includes orientation and mirroring metadata.
  public static func convertFrameToImageAsync(frame: Frame) async throws -> UIImage {
    guard let sampleBuffer = frame.sampleBuffer else {
      throw CameraError(message: "This frame has been disposed.")
    }
    let orientation = frame.metadata.uiImageOrientation
    return try await queue.perform { try sampleBuffer.toUIImage(orientation: orientation) }
  }

  /// Converts the ``Depth`` frame to an `UIImage`.
  ///
  /// The resulting `UIImage` will be a grey-scale RGB image,
  /// where black pixels are far away, and white pixels are close by.
  ///
  /// Returns a `UIImage` that visualizes the depth map and includes orientation and mirroring metadata. Throws if the Depth Frame is disposed or conversion fails.
  public static func convertDepthToImage(depth: Depth) throws -> UIImage {
    let depthData = try depth.getDepthData()
    return try depthData.toUIImage(orientation: depth.metadata.uiImageOrientation)
  }

  /// Asynchronously converts the ``Depth`` Frame to a `UIImage` that visualizes its depth map.
  ///
  /// Conversion runs on a shared serial queue. The depth data is retained before that queue hop. The image includes orientation and mirroring metadata.
  /// - Throws: If the Depth Frame is disposed or conversion fails.
  public static func convertDepthToImageAsync(depth: Depth) async throws -> UIImage {
    let depthData = try depth.getDepthData()
    let orientation = depth.metadata.uiImageOrientation
    return try await queue.perform { try depthData.toUIImage(orientation: orientation) }
  }
}
