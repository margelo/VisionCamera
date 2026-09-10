// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation
import Foundation
import UIKit

/// Converts Camera Frames and depth maps into UIKit images.
///
/// Conversions render into new images on a shared serial queue. The returned images carry the sample's
/// orientation and mirroring metadata. Native input buffers are retained until conversion completes.
public enum FrameConverter {
  private static let queue = DispatchQueue(label: "com.margelo.camera.image-conversion", qos: .userInitiated)

  /// Renders a Frame into a UIKit image.
  /// - Throws: A ``MediaError`` if the native sample is invalid or has no image, a rendering error,
  ///   or cancellation before conversion begins.
  public static func image(from frame: Frame) async throws -> UIImage {
    try await queue.perform {
      _ = try frame.validatedPixelBuffer()
      return try frame.sampleBuffer.image(orientation: frame.metadata.uiImageOrientation)
    }
  }

  /// Renders a depth or disparity map into a UIKit image.
  ///
  /// Core Image determines the rendered representation from the native depth data.
  /// - Throws: A rendering error, or cancellation before conversion begins.
  public static func image(from depth: Depth) async throws -> UIImage {
    try await queue.perform {
      try depth.depthData.image(orientation: depth.metadata.uiImageOrientation)
    }
  }
}
