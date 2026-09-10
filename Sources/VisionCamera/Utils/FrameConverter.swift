// Copyright © 2025 Marc Rousavy @ Margelo

import AVFoundation
import Foundation
import UIKit

public final class FrameConverter {
  private let queue = DispatchQueue(label: "com.margelo.camera.image-conversion", qos: .userInitiated)

  public init() {}

  public func convertFrameToImage(frame: Frame) throws -> UIImage {
    guard let sampleBuffer = frame.sampleBuffer else {
      throw CameraError(message: "This frame has been disposed.")
    }
    return try sampleBuffer.toUIImage(orientation: frame.metadata.uiImageOrientation)
  }

  public func convertFrameToImageAsync(frame: Frame) async throws -> UIImage {
    guard let sampleBuffer = frame.sampleBuffer else {
      throw CameraError(message: "This frame has been disposed.")
    }
    let orientation = frame.metadata.uiImageOrientation
    return try await queue.perform { try sampleBuffer.toUIImage(orientation: orientation) }
  }

  public func convertDepthToImage(depth: Depth) throws -> UIImage {
    let depthData = try depth.getDepthData()
    return try depthData.toUIImage(orientation: depth.metadata.uiImageOrientation)
  }

  public func convertDepthToImageAsync(depth: Depth) async throws -> UIImage {
    let depthData = try depth.getDepthData()
    let orientation = depth.metadata.uiImageOrientation
    return try await queue.perform { try depthData.toUIImage(orientation: orientation) }
  }
}
