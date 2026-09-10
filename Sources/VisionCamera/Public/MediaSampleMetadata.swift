//
//  MediaSampleMetadata.swift
//  VisionCamera
//
//  Created by Marc Rousavy on 29.10.25.
//

import AVFoundation
import Foundation
import UIKit

public struct MediaSampleMetadata {
  public let timestamp: CMTime
  public let orientation: CameraOrientation
  public let isMirrored: Bool

  public init(timestamp: CMTime, orientationFromOutput output: AVCaptureOutput) throws {
    guard let connection = output.connection(with: .video) else {
      throw CameraError(message: "Output \(output) does not have a video connection!")
    }
    self.init(timestamp: timestamp, orientationFromConnection: connection)
  }
  public init(timestamp: CMTime, orientationFromConnection connection: AVCaptureConnection) {
    self.timestamp = timestamp
    self.orientation = connection.orientation
    self.isMirrored = connection.isVideoMirrored
  }
  public init(timestamp: CMTime, orientation: CameraOrientation, isMirrored: Bool) {
    self.timestamp = timestamp
    self.orientation = orientation
    self.isMirrored = isMirrored
  }

  public var uiImageOrientation: UIImage.Orientation {
    return orientation.toUIImageOrientation(isMirrored: isMirrored)
  }
}
