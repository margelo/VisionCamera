//
//  MediaSampleMetadata.swift
//  VisionCamera
//
//  Created by Marc Rousavy on 29.10.25.
//

import AVFoundation
import Foundation
import UIKit

/// Presentation timestamp, orientation, and mirroring metadata for a Camera media sample.
public struct MediaSampleMetadata {
  /// The media sample's presentation timestamp.
  public let timestamp: CMTime
  /// The sample's rotation relative to the output's target orientation.
  public let orientation: CameraOrientation
  /// Whether the sample must be interpreted as mirrored along its vertical axis.
  public let isMirrored: Bool

  /// Creates metadata from the timestamp and the output's video connection.
  ///
  /// - Throws: If the output has no video connection.
  public init(timestamp: CMTime, orientationFromOutput output: AVCaptureOutput) throws(ConfigurationError) {
    guard let connection = output.connection(with: .video) else {
      throw ConfigurationError.outputNotConnected
    }
    self.init(timestamp: timestamp, orientationFromConnection: connection)
  }
  /// Creates metadata from the timestamp and the connection's orientation and mirroring settings.
  public init(timestamp: CMTime, orientationFromConnection connection: AVCaptureConnection) {
    self.timestamp = timestamp
    self.orientation = connection.orientation
    self.isMirrored = connection.isVideoMirrored
  }
  /// Creates metadata from an explicit timestamp, orientation, and mirroring setting.
  public init(timestamp: CMTime, orientation: CameraOrientation, isMirrored: Bool) {
    self.timestamp = timestamp
    self.orientation = orientation
    self.isMirrored = isMirrored
  }

  /// The UIKit image orientation combining this sample's rotation and mirroring metadata.
  public var uiImageOrientation: UIImage.Orientation {
    return orientation.toUIImageOrientation(isMirrored: isMirrored)
  }
}
